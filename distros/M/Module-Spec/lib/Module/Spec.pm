
package Module::Spec;
$Module::Spec::VERSION = '0.5.1';
# ABSTRACT: Load modules based on specifications
use 5.010;

# use strict;
# use warnings;

BEGIN {
    require Module::Spec::V1;
    *croak = \&Module::Spec::V1::croak;
}

sub new {
    my ( $self, %args ) = @_;

    croak qq{What version?} unless exists $args{ver};

    my $v = $args{ver};
    unless ( defined $v && $v =~ /\A[0-9]+\z/ ) {
        croak qq{Invalid version ($v)} if defined $v;
        croak qq{Undefined version};
    }

    require Module::Spec::OO;
    return bless {}, Module::Spec::OO->create_class($v);
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Module::Spec;
#pod
#pod     my $ms = Module::Spec->new(ver => 1);
#pod     $ms->need_module('Mango~2.3');
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<This is alpha software. The API is likely to change.>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Spec - Load modules based on specifications

=head1 VERSION

version 0.5.1

=head1 SYNOPSIS

    use Module::Spec;

    my $ms = Module::Spec->new(ver => 1);
    $ms->need_module('Mango~2.3');

=head1 DESCRIPTION

B<This is alpha software. The API is likely to change.>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
