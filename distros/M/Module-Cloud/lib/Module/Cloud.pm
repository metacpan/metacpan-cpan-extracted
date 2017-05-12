use 5.008;
use strict;
use warnings;

package Module::Cloud;
our $VERSION = '1.100861';
# ABSTRACT: Generates a tag cloud for modules used in given code
use HTML::TagCloud;
use File::Find::Rule::MMagic;
use Module::ExtractUse;
use parent 'Class::Accessor::Complex';
__PACKAGE__
    ->mk_new
    ->mk_array_accessors('dir');

sub get_cloud {
    my $self = shift;
    my @text_files;
    for my $dir ($self->dir) {
        push @text_files, grep { !/\/Makefile.PL$/ }
          grep { !/\.t$/ }
          grep { !/\/\.svn\// }
          find(file => magic => [qw(text/* x-system/*)], in => $dir);
    }
    my $extractor = Module::ExtractUse->new;
    my %modules;
    for my $textfile (@text_files) {
        my $used = $extractor->extract_use($textfile);
        $modules{$_}++ for keys %{ $used->{found} };
    }
    my $cloud = HTML::TagCloud->new;
    while (my ($module, $count) = each %modules) {
        $cloud->add($module, "http://search.cpan.org/search?query=$module",
            $count);
    }
    $cloud;
}
1;


__END__
=pod

=head1 NAME

Module::Cloud - Generates a tag cloud for modules used in given code

=head1 VERSION

version 1.100861

=head1 SYNOPSIS

  use Module::Cloud;
  my @dirs = qw(foo bar baz);
  my $clouder = Module::Cloud->new(dir => \@dirs);
  my $cloud = $clouder->get_cloud;  # returns an HTML::TagCloud object
  print $cloud->html_and_css;

=head1 DESCRIPTION

This class traverses the given directories, searches for perl code, extracts
the modules used by this code and generates a L<HTML::TagCloud> object that
gives an impression of how often each module is used.

=head1 METHODS

=head2 get_cloud

  my $cloud = $clouder->get_cloud;

Traverses the directories set on the C<dir> accessor and searches for files
containing perl code. For each such file, the modules it uses are extracted.
From this data a L<HTML::TagCloud> object is created and returned. The more
often a module is used the bigger it will appear in the tag cloud.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Module-Cloud>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Module-Cloud/>.

The development version lives at
L<http://github.com/hanekomu/Module-Cloud/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

