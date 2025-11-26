package Software::Policies::Contributing;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create project policy file: Contributing

our $VERSION = '0.001';

use Carp;

use Module::Load qw( load );

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub create {
    my ( $self, %args ) = @_;
    my $class = $args{'class'} // 'PerlDistZilla';

    my $module = __PACKAGE__ . q{::} . $class;
    load $module;
    my $m = $module->new();
    my %r = $m->create(%args);
    return \%r;
}

sub get_available_classes_and_versions {
    return {
        'PerlDistZilla' => {
            versions => {
                '1' => 1,
            },
            formats => {
                'markdown' => 1,
                'text'     => 1,
            },
        },
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Policies::Contributing - Create project policy file: Contributing

=head1 VERSION

version 0.001

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

Available classes: B<Perl::Dist::Zilla> (default).

=item version

Available versions: 1 (default), text.

=item format

Available formats: markdown (default), text.

=back

=head2 get_available_classes_and_versions

Return a hash with classes as keys. Example:

    {
        'Perl::Dist::Zilla' => {
            versions => {
                '1' => 1,
            },
            formats => {
                'markdown' => 1,
                'text'     => 1,
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
