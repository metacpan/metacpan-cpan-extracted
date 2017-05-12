package Socialtext::EditPage;
use warnings;
use strict;
use Carp qw/croak/;
use File::Temp;
use Socialtext::Resting::DefaultRester;
use Socialtext::Resting;
use JSON::XS;

=head1 NAME

Socialtext::EditPage - Edit a wiki page using your favourite EDITOR.

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Fetch a page, edit it, and then post it.

    use Socialtext::EditPage;

    # The rester is set with the server and workspace
    my $rester = Socialtext::Resting->new(%opts);

    my $s = Socialtext::EditPage->new(rester => $rester);
    $s->edit_page('Snakes on a Plane');

=head1 FUNCTIONS

=head2 new( %opts )

Arguments:

=over 4

=item rester

Users must provide a Socialtext::Resting object setup to use the desired 
workspace and server.

=item pull_includes

If true, C<include> wafls will be inlined into the page as extraclude
blocks.

=back

=cut

sub new {
    my ($class, %opts) = @_;
    $opts{rester} ||= Socialtext::Resting::DefaultRester->new(%opts);
    my $self = { %opts };
    bless $self, $class;
    return $self;
}

=head2 C<edit_page( %opts )>

This method will fetch the page content, and then run $EDITOR on the file.
After the file has been edited, it will be put back on the wiki server.

Arguments:

=over 4

=item page

The name of the page you wish to edit.

=item callback

If supplied, callback will be called after the page has been edited.  This
function will be passed the edited content, and should return the content to
be put onto the server.

=item summary_callback

If supplied, callback will be called after the page has been edit.  This 
function should return the edit summary text for this edit, if desired.

=item tags 

If supplied, these tags will be applied to the page after it is updated.

=item output

If supplied, the page will be saved to the given file instead of edited. 
The page will not be uploaded to the server.

=item template

If specified, this page will be used as the template for a new page.

=back

=cut

sub edit_page {
    my $self = shift;
    my %args = @_;
    my $page = $self->{page} = delete $args{page};
    croak "page is mandatory" unless $page;

    my $rester = $self->{rester};
    my $content = $self->_get_page($page);

    my $tags = delete $args{tags} || [];
    if ($args{template}) {
        if ($rester->response->code eq '404') {
            $content = $self->_get_page($args{template});
        }
        else {
            print "Not using template '$args{template}' - page already "
                 . "exists.\n";
        }
        $rester->accept('text/plain');
        my @tmpl_tags = grep { !/^template$/ } $rester->get_pagetags($args{template});
        push @$tags, @tmpl_tags;
    }

    if ($args{output}) {
        _write_file($args{output}, $content);
        print "Wrote $page content to $args{output}\n";
        return;
    }

    my $orig_content = $content;
    my $edit_summary;
    while (1) {
        my $new_content = $content;
        $new_content = $self->_pre_process_special_wafls($new_content);
        $new_content = $self->_edit_content($new_content);

        if ($orig_content eq $new_content) {
            print "$page did not change.\n";
            return;
        }

        $new_content = $args{callback}->($new_content) if $args{callback};

        $new_content = $self->_process_special_wafls($new_content);

        $edit_summary ||= $args{summary_callback}->() if $args{summary_callback};

        eval { 
            $page =~ s#/#-#g; # cannot have /'s in the page name
            $rester->put_page($page, {
                    content => $new_content,
                    date => scalar(gmtime),
                    ($edit_summary ? (edit_summary => $edit_summary) : ()),
                }
            );
        };
        last unless $@;
        if ($@ =~ /412/) { # collision detected!
            print "A collision was detected.  I will merge the changes and "
                  . "re-open your editor.\nHit enter.\n";
            sleep 2;
            print "Merging...\n";
            $orig_content = $self->_get_page($page);
            my $updated_file = _write_file(undef, $orig_content);
            my $orig_file = _write_file(undef, $content);
            my $our_file  = _write_file(undef, $new_content);

            # merge the content and re-edit
            # XXX: STDERR is not redirected.  Should use IPC::Run.  However,
            # it's nice to be able to create pages w/ quotes and other shell
            # characters in their name.
            system(qw(merge -L yours -L original -L), "new edit", $our_file,
                   $orig_file, $updated_file);

            $content = _read_file($our_file);
        }
        else {
            $self->_handle_error($@, $page, $new_content);
        }
    }

    if ($tags) {
        $tags = [$tags] unless ref($tags) eq 'ARRAY';
        for my $tag (@$tags) {
            print "Putting page tag $tag on $page\n";
            $rester->put_pagetag($page, $tag);
        }
    }

    print "Updated page $page\n";
}

=head2 C<edit_last_page( %opts )>

This method will retrieve a last of all pages tagged with the supplied
tag, and then open the latest one for edit.

Arguments are passed through to edit_page(), accept for:

=over 4

=item tag

The name of the tag you wish to edit.

=back

=cut

sub edit_last_page {
    my $self = shift;
    my %opts = @_;

    my $tag = delete $opts{tag} || croak "tag is mandatory";
    my $rester = $self->{rester};
    $rester->accept('application/json');
    my $pages = decode_json($rester->get_taggedpages($tag));
    unless (@$pages) {
        die "No pages found tagged '$tag'\n";
    }
    my @pages = sort { $b->{modified_time} <=> $a->{modified_time} }
                @$pages;
    my $newest_page = shift @pages;
    print "Editing '$newest_page->{name}'\n";
    $self->edit_page(page => $newest_page->{page_id}, %opts);
}

sub _get_page {
    my $self = shift;
    my $page_name = shift;
    my $rester = $self->{rester};
    $rester->accept('text/x.socialtext-wiki');

    my $page = $rester->get_page($page_name);

    if ($self->{pull_includes}) {
        while ($page =~ m/({include:?\s+\[([^\]]+)\]\s*}\n)/smg) {
            my $included_page = $2;
            my ($match_start, $match_size) = ($-[0], $+[0] - $-[0]);
            print "Pulling include in [$page_name] - [$included_page]\n";
            my $pulled_content = $self->_get_page($included_page);
            chomp $pulled_content;
            my $included_content = ".pulled-extraclude [$included_page]\n"
                                   . "$pulled_content\n"
                                   . ".pulled-extraclude\n";

            substr($page, $match_start, $match_size) = $included_content;
        }
    }

    return $page;
}

sub _edit_content {
    my $self = shift;
    my $content = shift;

    my $workspace = $self->{rester}->workspace || '';
    (my $page = $self->{page}) =~ s#/#_#g;
    my $filename = File::Temp->new( 
        TEMPLATE => "$workspace.$page.XXXX", 
        SUFFIX => '.wiki' 
    );
    _write_file($filename, $content);
    my $editor   = $ENV{EDITOR} || '/usr/bin/vim';

    system( $editor, $filename );

    return _read_file($filename);
}

{
    my @special_wafls = (
        [ '.extraclude' => '.e-x-t-r-a-c-l-u-d-e' ],
        [ '.pulled-extraclude' => '.extraclude', 'pre-only' ],
    );

    sub _pre_process_special_wafls {
        my $self = shift;
        my $text = shift;

        # Escape special wafls
        for my $w (@special_wafls) {
            my $wafl = $w->[0];
            my $expanded = $w->[1];
            $text =~ s/\Q$wafl\E\b/$expanded/g;
        }
        return $text;
    }

    sub _process_special_wafls {
        my $self = shift;
        my $text = shift;
        my $rester = $self->{rester};

        my $included_content = sub {
            my $type    = lc shift;
            my $name    = shift;
            my $newline = shift || '';

            if ($type eq 'clude') {
                return "{include: [$name]}\n";
            }
            elsif ($type eq 'link') {
                return "[$name]$newline";
            }
            die "Unknown extrathing: $type";
        };

        while ($text =~ s/\.extra(clude|link)\s     # $1 is title
                          \[([^\]]+)\]              # $2 is [name]
                          (\n?)                      # $3 is extra newline
                          (.+?)
                          \.extra(?:clude|link)\n
                         /$included_content->($1, $2, $3)/ismex) {
            my ($page, $new_content) = ($2, $4);
            print "Putting extraclude '$page'\n";
            eval {
                $rester->put_page($page, $new_content);
            };
            $self->_handle_error($@, $page, $new_content) if $@;
        }

        # Unescape special wafls
        for my $w (@special_wafls) {
            next if $w->[2];
            my $wafl = $w->[0];
            my $expanded = $w->[1];
            $text =~ s/\Q$expanded\E\b/$wafl/ig;
        }

        return $text;
    }

}

sub _handle_error {
    my ($self, $err, $page, $content) = @_;
    my $file = Socialtext::Resting::_name_to_id($page) . ".sav";
    my $i = 0;
    while (-f $file) {
        $i++;
        $file =~ s/\.sav(?:\.\d+)?$/\.sav\.$i/;
    }
    warn "Failed to write '$page', saving to $file\n";
    _write_file($file, $content);
    die "$err\n";
}

sub _write_file {
    my ($filename, $content) = @_;
    $filename ||= File::Temp->new( SUFFIX => '.wiki' );
    open(my $fh, ">$filename") or die "Can't open $filename: $!";
    print $fh $content || '';
    close $fh or die "Can't write $filename: $!";
    return $filename;
}

sub _read_file {
    my $filename = shift;
    open(my $fh, $filename) or die "unable to open $filename $!\n";
    my $new_content;
    {
        local $/;
        $new_content = <$fh>;
    }
    close $fh;
    return $new_content;
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-editpage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Socialtext::EditPage

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Socialtext-Resting-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Socialtext-Resting-Utils>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Socialtext-Resting-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Socialtext-Resting-Utils>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
