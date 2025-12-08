# no critic (ControlStructures::ProhibitPostfixControls)
package Software::Policies::CodeOfConduct;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create project policy file: Code of Conduct

our $VERSION = '0.002';

use Carp;
use Module::Load qw( load );

use Module::Loader ();

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub create {
    my ( $self, %args ) = @_;
    my $class  = delete $args{'class'} // 'ContributorCovenant';
    my $module = __PACKAGE__ . q{::} . $class;
    load $module;
    my $m = $module->new();
    my %r = $m->create(%args);

    return \%r;
}

sub get_available_classes_and_versions {
    return {
        'ContributorCovenant' => {
            versions => {
                '1.4' => 1,
                '2.0' => 1,
                '2.1' => 1,
            },
            formats => {
                'markdown' => 1,
            },
        },
    };
}

# sub _filename {
#     my ($format) = @_;
#     my %formats = (
#         'markdown' => 'CODE_OF_CONDUCT.md',
#         'text'     => 'CODE_OF_CONDUCT.txt',
#     );
#     return $formats{$format};
# }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Policies::CodeOfConduct - Create project policy file: Code of Conduct

=head1 VERSION

version 0.002

=begin Pod::Coverage




=end Pod::Coverage

=begin stopwords




=end stopwords

=head1 METHODS

=head2 new

=head2 create

Create the policy.

Options:

=over 8

=item class

Available classes: B<Simple> (default).

=item version

Available versions: 1 (default).

=item format

Available formats: markdown (default).

=item options

Required options:

=over 8

=item name

=item reporting_address

=back

=back

=head2 get_available_classes_and_versions

Return a hash with classes as keys. Example:

    {
        'ContributorCovenant' => {
            versions => {
                '1.4' => 1,
                '2.0' => 1,
                '2.1' => 1,
            },
            formats => {
                'markdown' => 1,
            },
        },
    }

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
