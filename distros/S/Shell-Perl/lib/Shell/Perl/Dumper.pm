package Shell::Perl::Dumper;

use strict;
use warnings;

our $VERSION = '0.004';

use base qw(Class::Accessor); # to get a new() for free

package Shell::Perl::Dumper::Plain;

our @ISA = qw(Shell::Perl::Dumper); # to get a new() for free

sub is_available {
    return 1; # always available - no dependency but Perl
}

sub dump_scalar {
    shift;
    return "$_[0]" . "\n";
}

sub dump_list {
    shift;
    local $" = "\t";
    return "@_" . "\n";
}

package Shell::Perl::Data::Dump;

our @ISA = qw(Shell::Perl::Dumper); # to get a new() for free

# XXX make a Data::Dump object an instance variable

sub _dump_code_filter {
    my ($ctx, $object_ref) = @_;
    return undef unless $ctx->is_code;

    require B::Deparse;
    my $code = 'sub ' . (B::Deparse->new)->coderef2text($object_ref);
    return { dump => $code };
}

sub is_available {
    return eval { require Data::Dump::Filtered; 1 };
}

sub dump_scalar {
    shift;
    require Data::Dump::Filtered;
    return Data::Dump::Filtered::dump_filtered(shift, \&_dump_code_filter) . "\n";
}

sub dump_list {
    shift;
    require Data::Dump::Filtered;
    return Data::Dump::Filtered::dump_filtered(@_, \&_dump_code_filter) . "\n";
}

package Shell::Perl::Data::Dumper;

our @ISA = qw(Shell::Perl::Dumper);

# XXX make a Data::Dumper object an instance variable
#     but OO Data::Dumper is very annoying

sub is_available {
    return eval { require Data::Dumper; 1 };
}

sub dump_scalar {
    shift;
    require Data::Dumper;
    local $Data::Dumper::Deparse = 1;
    return Data::Dumper->Dump([shift], [qw($var)]);
}

sub dump_list {
    #goto &dump_scalar if @_==2; # fallback to dump_scalar if only one
    shift;
    require Data::Dumper;
    local $Data::Dumper::Deparse = 1;
    return Data::Dumper->Dump([[@_]], [qw(*var)]);
}

package Shell::Perl::Dumper::YAML;

our @ISA = qw(Shell::Perl::Dumper);

sub _require_one_of {
    my @modules = @_;
    for (@modules) {
        my $ret = eval "require $_; 1";
        warn "pirl: $_ loaded ok\n" if $ret; # XXX
        return $_ if $ret;
    }
    return undef
}

our $YAML_PACKAGE;

sub is_available {
    #return eval { require YAML; 1 };
    $YAML_PACKAGE = _require_one_of(qw(YAML::Syck YAML));
    if ($YAML_PACKAGE) {
        $YAML_PACKAGE->import(qw(Dump));
        do { no strict 'refs'; ${ $YAML_PACKAGE . '::DumpCode' } = 1 };
        return 1
    } else {
        return undef;
    }

}

sub dump_scalar {
    shift;
    #require YAML; # done by &is_available
    return Dump(shift);
}

sub dump_list { # XXX
    shift;
    #require YAML; # done by &is_available
    return Dump(@_);
}

package Shell::Perl::Data::Dump::Streamer;

our @ISA = qw(Shell::Perl::Dumper);

sub is_available {
    return eval { require Data::Dump::Streamer; 1 };
}

sub dump_scalar {
    shift;
    require Data::Dump::Streamer;
    return Data::Dump::Streamer::Dump(shift)->Names('$var')->Out;
}

sub dump_list {
    #goto &dump_scalar if @_==2; # fallback to dump_scalar if only one
    shift;
    require Data::Dump::Streamer;
    return Data::Dump::Streamer::Dump([@_])->Names('*var')->Out;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Shell::Perl::Dumper - Dumpers for Shell::Perl

=head1 SYNOPSYS

    use Shell::Perl::Dumper;
    $dumper = Shell::Perl::Dumper::Plain->new;
    print $dumper->dump_scalar($scalar);
    print $dumper->dump_list(@list);

=head1 DESCRIPTION

In C<pirl>, the result of the evaluation is transformed
into a string to be printed. As this result may be a pretty
complex data structure, the shell provides a hook
for you to pretty-print these answers just the way you want.

By default, C<pirl> will try to convert the results
via C<Data::Dump>. That means the output will be Perl
code that may be run to get the data structure again.
Alternatively, the shell may use C<Data::Dumper>
or C<Data::Dump::Streamer>
with almost the same result with respect to the
representation as Perl code. (But the output of the
modules differ enough for sufficiently complex data.)

Other options are to set the output to produce YAML
or a plain simple-minded solution which basically
turns the result to string via simple interpolation.

All of these are implemented via I<dumper objects>.
Dumpers are meant to be used like that:

   $dumper = Some::Dumper::Class->new; # build a dumper

   $s = $dumper->dump_scalar($scalar); # from scalar to string

   $s = $dumper->dump_list(@list); # from list to string

=head2 METHODS

The following methods compose the expected API
of a dumper, as used by L<Shell::Perl>.

=over 4

=item B<new>

    $dumper = $class->new(@args);

Constructs a dumper.

=item B<dump_scalar>

    $s = $dumper->dump_scalar($scalar);

Turns a scalar into a string representation.

=item B<dump_list>

    $s = $dumper->dump_list(@list);

Turns a list into a string representation.

=item B<is_available>

    $ok = $class->is_available

This is an I<optional> class method. If it exists, it
means that the class has external dependencies (like
C<Shell::Perl::Data::Dump> depends on C<Data::Dump>)
and whether these may be loaded when needed. If they can,
this method returns true. Otherwise, returning false
means that a dumper instance of this class probably
cannot work. This is typically because the dependency
is not installed or cannot be loaded due to
an installation problem.

This is the algorithm used by L<Shell::Perl> XXX
XXX XXX

    1.

=back

=head1 THE STANDARD DUMPERS

L<Shell::Perl> provides four standard dumpers:

    * Shell::Perl::Data::Dump
    * Shell::Perl::Data::Dumper
    * Shell::Perl::Data::Dump::Streamer
    * Shell::Perl::Dumper::YAML
    * Shell::Perl::Dumper::Plain

which corresponds to the four options of the
command C< :set out >: "D", "DD", "DDS", "Y", and "P"
respectively.

=head2 Data::Dump

The package C<Shell::Perl::Data::Dump> implements a dumper
which uses L<Data::Dump> to turn Perl variables into
a string representation.

It is used like this:

    use Shell::Perl::Dumper;

    if (!Shell::Perl::Data::Dump->is_available) {
        die "the dumper cannot be loaded correctly"
    }
    $dumper = Shell::Perl::Data::Dump->new;
    print $dumper->dump_scalar($scalar);
    print $dumper->dump_list(@list);

Examples of its output:

    pirl > :set out D

    pirl > { a => 3 } #scalar
    { a => 3 }

    pirl > (1, 2, "a") #list
    (1, 2, "a")

=head2 Data::Dumper

The package C<Shell::Perl::Data::Dumper> implements a dumper
which uses L<Data::Dumper> to turn Perl variables into
a string representation.

It is used like this:

    use Shell::Perl::Dumper;

    if (!Shell::Perl::Data::Dumper->is_available) {
        die "the dumper cannot be loaded correctly"
    }
    $dumper = Shell::Perl::Data::Dumper->new;
    print $dumper->dump_scalar($scalar);
    print $dumper->dump_list(@list);

Examples of its output:

    pirl > :set out DD

    pirl > { a => 3 } #scalar
    @var = (
             {
               'a' => 3
             }
           );

    pirl > (1, 2, "a") #list
    @var = (
             1,
             2,
             'a'
           );

=head2 YAML

The package C<Shell::Perl::Dumper::YAML> implements a dumper
which uses L<YAML::Syck> or L<YAML> to turn Perl variables into
a string representation.

It is used like this:

    use Shell::Perl::Dumper;

    if (!Shell::Perl::Dumper::YAML->is_available) {
        die "the dumper cannot be loaded correctly"
    }
    $dumper = Shell::Perl::Dumper::YAML->new;
    print $dumper->dump_scalar($scalar);
    print $dumper->dump_list(@list);

Examples of its output:

    pirl > :set out Y

    pirl @> { a => 3 } #scalar
    ---
    a: 3

    pirl @> (1, 2, "a") #list
    --- 1
    --- 2
    --- a

When loading, C<YAML::Syck> is preferred to C<YAML>. If it
is not available, the C<YAML> module is the second option.

=head2 Data::Dump::Streamer

The documentation is yet to be written.

=head2 Plain Dumper

The package C<Shell::Perl::Dumper::Plain> implements a dumper
which uses string interpolation to turn Perl variables into
strings.

It is used like this:

    use Shell::Perl::Dumper;

    $dumper = Shell::Perl::Dumper::Plain->new;
    print $dumper->dump_scalar($scalar);
    print $dumper->dump_list(@list);

Examples of its output:

    pirl > :set out P

    pirl > { a => 3 } #scalar
    HASH(0x1094d2c0)

    pirl > (1, 2, "a") #list
    1       2       a

=head1 SEE ALSO

See L<Shell::Perl> for more documentation.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007–2017 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
