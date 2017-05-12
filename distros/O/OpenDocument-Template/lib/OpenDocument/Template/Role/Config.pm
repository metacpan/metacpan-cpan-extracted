package OpenDocument::Template::Role::Config;
{
  $OpenDocument::Template::Role::Config::VERSION = '0.002';
}
# ABSTRACT: OpenDocument::Template role for config

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use autodie;

use Config::Any;

subtype 'OpenDocument::Template::Types::Config'
    => as 'HashRef';

coerce 'OpenDocument::Template::Types::Config'
    => from 'Str'
        => via {
            return unless -f;

            my $configs = Config::Any->load_files({
                files   => [ $_ ],
                use_ext => 1,
            });
            return unless $configs;
            return unless ref($configs) eq 'ARRAY';

            for (@$configs) {
                my ($filename, $config) = %$_;
                return $config;
            }
        };

has 'config' => (
    is       => 'rw',
    isa      => 'OpenDocument::Template::Types::Config',
    required => 1,
    coerce   => 1,
    default  => sub { { templates => {} } },
);

1;


=pod

=encoding utf-8

=head1 NAME

OpenDocument::Template::Role::Config - OpenDocument::Template role for config

=head1 VERSION

version 0.002

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

