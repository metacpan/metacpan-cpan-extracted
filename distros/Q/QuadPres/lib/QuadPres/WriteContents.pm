package QuadPres::WriteContents;
$QuadPres::WriteContents::VERSION = '0.28.3';
use 5.016;
use strict;
use warnings;
use autodie;

use MooX qw/ late /;

has '_contents' =>
    ( isa => "HashRef", is => "ro", init_arg => "contents", required => 1, );


my @output_contents_keys_order = (qw(url title subs images));

my %output_contents_keys_values =
    ( map { $output_contents_keys_order[$_] => $_ }
        ( 0 .. $#output_contents_keys_order ) );

sub _get_key_order
{
    my ($key) = (@_);

    return
        exists( $output_contents_keys_values{$key} )
        ? $output_contents_keys_values{$key}
        : scalar(@output_contents_keys_order);
}

sub _sort_keys
{
    my ($hash) = @_;
    return [
        sort { _get_key_order($a) <=> _get_key_order($b) }
            keys(%$hash)
    ];
}
my %special_chars = (
    "\n" => "\\n",
    "\t" => "\\t",
    "\r" => "\\r",
    "\f" => "\\f",
    "\b" => "\\b",
    "\a" => "\\a",
    "\e" => "\\e",
);

sub _string_to_perl
{
    my $s = shift;
    $s =~ s/([\\\"])/\\$1/g;

    $s =~ s/([\n\t\r\f\b\a\e])/$special_chars{$1}/ge;
    $s =~ s/([\x00-\x1F\x80-\xFF])/sprintf("\\x%.2xd", ord($1))/ge;

    return $s;
}


sub update_contents
{
    my ($self) = @_;

    open my $contents_fh, ">", "Contents.pm";
    print {$contents_fh}
        "package Contents;\n\nuse strict;\n\nmy \$contents = \n";

    print {$contents_fh} $self->_stringify_contents();

    print {$contents_fh} <<"EOF";

sub get_contents
{
    return \$contents;
}

1;
EOF

    close($contents_fh);
}

sub _stringify_contents
{
    my $self = shift;

    my $contents = $self->_contents();

    my $indent = "    ";

    my @branches = ( { 'b' => $contents, 'i' => -1 } );

    my $ret = "";

MAIN_LOOP: while ( @branches > 0 )
    {
        my $last_element = $branches[$#branches];
        my $b            = $last_element->{'b'};
        my $i            = $last_element->{'i'};
        my $p1           = $indent x ( 2 * ( scalar(@branches) - 1 ) );
        my $p2           = $p1 . $indent;
        my $p3           = $p2 . $indent;
        if ( $i < 0 )
        {
            $ret .= "${p1}\{\n";
            foreach my $field (qw(url title))
            {
                if ( exists( $b->{$field} ) )
                {
                    $ret .= "${p2}'$field' => \""
                        . _string_to_perl( $b->{$field} ) . "\",\n";
                }
            }

            if ( exists( $b->{'subs'} ) )
            {
                $ret .= "${p2}'subs' =>\n";
                $ret .= "${p2}\[\n";

                # push @branches { 'b' => $b->{'subs'} }
            }
            $last_element->{'i'} = 0;
            next MAIN_LOOP;
        }
        elsif (( !exists( $b->{'subs'} ) )
            || ( $i >= scalar( @{ $b->{'subs'} } ) ) )
        {
            $ret .= "${p2}],\n" if ( exists( $b->{'subs'} ) );
            if ( exists( $b->{'images'} ) )
            {
                $ret .= "${p2}'images' =>\n";
                $ret .= "${p2}\[\n";
                foreach my $img ( @{ $b->{'images'} } )
                {
                    $ret .= "${p3}\"" . _string_to_perl($img) . "\",\n";
                }
                $ret .= "${p2}],\n";
            }
            pop(@branches);
            $ret .= "${p1}}" . ( ( @branches > 0 ) ? "," : ";" ) . "\n";
            next MAIN_LOOP;
        }
        else
        {
            push @branches, { 'b' => $b->{'subs'}->[$i], 'i' => -1 };
            ++( $last_element->{'i'} );
            next MAIN_LOOP;
        }
    }

    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

QuadPres::WriteContents - write the contents.

=head1 VERSION

version 0.28.3

=head1 SYNOPSIS

    my $obj = QuadPres::WriteContents->new({contents => $contents, });
    $obj->update_contents();

=head1 DESCTIPTION

QuadPres::WriteContents.

=head1 METHODS

=head2 $writer->update_contents()

Overwrite Contents.pm with the updated contents perl code.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/QuadPres>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=QuadPres>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/QuadPres>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/Q/QuadPres>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=QuadPres>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=QuadPres>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-quadpres at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=QuadPres>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/quad-pres>

  git clone https://github.com/shlomif/quad-pres.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/quad-pres/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
