package Muster::Hook::Include;
$Muster::Hook::Include::VERSION = '0.62';
use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;

use Carp 'croak';

=head1 NAME

Muster::Hook::Include - Muster include-page directive

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::Include> includes pages inside other pages.

=head1 METHODS

L<Muster::Hook::Include> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    my $callback = sub {
        my %args = @_;

        return $self->process(%args);
    };
    # Don't do page inclusion in the scanning phase;
    # it would be too confusing.
    $hookmaster->add_hook('includepage' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'includepage',
                call=>$callback,
                %args,
            );
        },
    );
    return $self;
} # register

=head2 process

Process page inclusion.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my @p = @{$args{params}};
    my %params = @p;
    my $pagename = $leaf->pagename;

    if (! exists $params{pagenames})
    {
	return "ERROR: missing pagenames parameter";
    }
    if ($phase eq $Muster::Hooks::PHASE_SCAN)
    {
        return "";
    }

    my @list = map { $self->{metadb}->bestlink($pagename, $_) } split ' ', $params{pagenames};

    # Do a naive solution first: simply include the raw text of the other pages
    # into this page, IFF they are of the same filetype.
    # This ought to work in most cases, if I'm sticking to Markdown for the default page type.
    my $this_filetype = $leaf->filetype;
    my @in_stuff = ();
    foreach my $page (@list)
    {
        my $info = $self->{metadb}->page_or_file_info($page);
        if ($info and $info->{filetype} eq $this_filetype)
        {
            my $new_leaf = Muster::LeafFile->new(
                pagename=>$info->{pagename},
                parent_page=>$info->{parent_page},
                filename=>$info->{filename},
                filetype=>$info->{filetype},
                is_page=>$info->{is_page},
                extension=>$info->{extension},
                name=>$info->{name},
                title=>$info->{title},
                date=>$info->{date},
                meta=>$info,
            );
            $new_leaf = $new_leaf->reclassify();
            if (!$new_leaf)
            {
                croak "ERROR: leaf did not reclassify\n";
            }
            push @in_stuff, $self->include_a_page($new_leaf);
        }
    }
    my $ret = join("\n", @in_stuff);
} # process

=head2 include_a_page

Include the content of one page into another.

=cut
sub include_a_page {
    my $self = shift;
    my $new_leaf = shift;

    my $content = $new_leaf->cooked;
    if ($content =~ /\[\[\!includepage/)
    {
        # the included page may have an includepage directive in it!
        my $cb = sub {
            my %args = @_;

            return $self->process(%args);
        };
        $new_leaf = $self->do_directives(
            no_scan=>1,
            directive=>'includepage',
            call=>$cb,
            leaf=>$new_leaf,
            phase=>$Muster::Hooks::PHASE_BUILD,
        );
        $content = $new_leaf->cooked;
    }
    return $content;
} # include_a_page

1;
