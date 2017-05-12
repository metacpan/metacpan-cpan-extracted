# ABSTRACT: A Selenese Test Case
package Parse::Selenese::TestSuite;
use Moose;
use Carp ();
use File::Basename;
use HTML::TreeBuilder;
use Parse::Selenese::TestCase;

our $VERSION = '0.006'; # VERSION

has 'cases' => (
    isa      => 'ArrayRef',
    is       => 'rw',
    required => 0,
    default  => sub { [] },
);

# Return whether the specified file is a test suite or not
# static method
sub _is_suite_file {
    my ($filename) = @_;

    die "Can' t read $filename " unless -r $filename;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($filename);

    my $table = $tree->look_down( 'id', 'suiteTable' );
    return !!$table;
}

# Bulk convert test cases in this suite
sub bulk_convert {
    my $self = shift;

    my @outfiles;
    foreach my $case ( @{ $self->cases } ) {
        push( @outfiles, $case->convert_to_perl );
    }
    return @outfiles;
}

sub case_file_names {
    map { $_->{filename} } __PACKAGE__->new(shift)->cases;
}

sub parse {
    my $self           = shift;
    my $suite_filename = $self->{filename};

    die " Can't read $suite_filename " unless -r $suite_filename;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($suite_filename);

    # base_urlを<link>から見つける
    my $base_url;
    foreach my $link ( $tree->find('link') ) {
        if ( $link->attr('rel') eq 'selenium.base' ) {
            $base_url = $link->attr('href');
        }
    }

    # <tbody>以下からコマンドを抽出
    my $tbody    = $tree->find('tbody');
    my $base_dir = File::Basename::dirname( $self->{filename} );
    my @cases;
    if ($tbody) {
        foreach my $tr ( $tbody->find('tr') ) {
            my $link = $tr->find('td')->find('a');
            if ($link) {
                my $case;
                eval {
                    $case = Parse::Selenese::TestCase->new(
                        $base_dir . '/' . $link->attr('href') );
                };
                if ($@) {
                    warn " Can't read test case $base_dir / "
                      . $link->attr('href')
                      . " : $! \n ";
                }
                push( @cases, $case ) if $case;
            }
        }
    }
    $tree = $tree->delete;

    $self->{cases} = \@cases;
}

1;


=pod

=head1 NAME

Parse::Selenese::TestSuite - A Selenese Test Case

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Parse::Selenese::TestSuite;
  my $testsuite = Parse::Selenese::TestSuite->new(filename => $some_file_name);
  my $testsuite = Parse::Selenese::TestSuite->new(content => $string);

=head1 DESCRIPTION

Parse::Selenese::TestSuite is a representation of a Selenium Selenese Test Suite.

=head2 Functions

=over

=item C<BUILD>

Moose method that runs after object initialization and attempts to parse
whatever content was provided.

=item C<as_html>

Return the test suite in HTML (Selenese) format.

=item C<as_HTML>

An alias to C<as_html>

=item C<as_perl>

Return the test suite as a string of Perl.

=item C<bulk_convert>

Return an array of C<Parse::Selenese::TestCase>s.

=item C<parse>

Parse the test suite from the file name or content that was previously set

=item C<case_file_names>

Return the file names for all test cases in the suite.

=back

=head1 NAME

Parse::Selenese::TestSuite

=head1 AUTHOR

Theodore Robert Campbell Jr E<lt>trcjr@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Theodore Robert Campbell Jr <trcjr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Theodore Robert Campbell Jr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

