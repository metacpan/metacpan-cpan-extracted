
package Module::Spec::V0;
$Module::Spec::V0::VERSION = '0.9.0';
# ABSTRACT: Module::Spec internal utilities
use 5.012;

# use warnings;

our @EXPORT_OK = qw(need_module try_module);

# _need_module($opts, $m, @v);
sub _need_module {
    my ( $opts, $m, @v ) = @_;
    _require_module($m) if $opts->{REQUIRE} // $opts->{require}->( $m, @v );
    $m->VERSION(@v) if @v;
    return wantarray ? ( $m, $m->VERSION ) : $m;
}

sub _opts {
    my %opts = ( require => 1, %{ shift // {} } );

    $opts{REQUIRE} = !!delete $opts{require}
      unless ref $opts{require} eq 'CODE';

    return \%opts;
}

# Diagnostics:
#  Can't locate Foo.pm in @INC (you may need to install the Foo module) (@INC contains:
#  Carp version 2.3 required--this is only version 1.40 at
#  Foo2 does not define $Foo2::VERSION--version check failed at

# _try_module($opts, $m, @v);
sub _try_module {
    my ( $opts, $m, @v ) = @_;
    if ( $opts->{REQUIRE} // $opts->{require}->( $m, @v ) ) {
        eval { _require_module($m) };
        if ($@) {
            my $err = $@;
            $err =~ /\ACan't locate\b/ ? return : die $err;
        }
    }
    if (@v) {
        eval { $m->VERSION(@v) };
        if ($@) {
            my $err = $@;
            $err =~ /\A\S+ version \S+ required\b/ ? return : die $err;
        }
    }
    return wantarray ? ( $m, $m->VERSION ) : $m;
}

# TODO need_modules($spec1, $spec1)

sub _require_module {
    ( my $f = "$_[0].pm" ) =~ s{::}{/}g;
    require $f;
}

sub croak {
    require Carp;
    no warnings 'redefine';
    *croak = \&Carp::croak;
    goto &croak;
}

### EXPERIMENTAL

# _generate_code($opts, $m, @v);
sub _generate_code {
    my $opts = shift;
    $opts->{context} ||= 'void';
    $opts->{indent}  ||= ' ' x 4;

    my ( $m, @v ) = @_;
    my $code = "require $m;\n";
    $code .= "$m->VERSION('$v[0]');\n" if @v;

    if ( $opts->{context} eq 'void' ) {

        # nothing to do
    }
    elsif ( $opts->{context} eq 'scalar' ) {
        $code .= "'$m';\n";
    }
    elsif ( $opts->{context} eq 'list' ) {
        $code .= "('$m', '$m'->VERSION);\n";
    }

    if ( $opts->{wrap} ) {
        $code =~ s/^/$opts->{indent}/mg if $opts->{indent};
        $code = "do {\n$code};\n";
    }

    return $code;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Spec::V0 - Module::Spec internal utilities

=head1 VERSION

version 0.9.0

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
