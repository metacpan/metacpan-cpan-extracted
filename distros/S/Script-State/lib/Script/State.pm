package Script::State;
use strict;
use warnings;
use PadWalker qw(var_name);
use Data::Dumper;

our $VERSION = '0.03';

our $DATAFILE;
our $SCRIPT_DATA;
our $VAR_REF;

sub script_state {
    my $name = var_name 1, \$_[0] or do {
        require Carp;
        Carp::croak('Invalid variable passed');
    };
    $VAR_REF->{$name} = \$_[0];

    if (exists $SCRIPT_DATA->{$name}) {
        $_[0] = $SCRIPT_DATA->{$name};
    } elsif ($#_ >= 1) {
        $_[0] = $_[1];
    }
}

sub store {
    if ($DATAFILE && $VAR_REF) {
        open my $fh, '>', $DATAFILE or do {
            warn "Could not open $DATAFILE: $!";
            return;
        };

        my $vars = { map { $_ => ${ $VAR_REF->{$_} } } keys %$VAR_REF };
        print $fh Data::Dumper->new([ $vars ])->Varname('VAR')->Terse(0)->Indent(1)->Purity(1)->Dump;
        close $fh;

        return 1;
    }
}

sub import {
    my ($class, %args) = @_;

    $DATAFILE = delete $args{-datafile} || do {
        require File::Spec;
        my ($vol, $dirs, $file) = File::Spec->splitpath($0);
        File::Spec->catpath($vol, $dirs, ".$file.pl");
    };

    $SCRIPT_DATA = -r $DATAFILE ? do { do $DATAFILE; no strict 'vars'; $VAR1 } : {}; ## no critic

    my $pkg = caller;
    no strict 'refs';
    *{ "$pkg\::script_state" } = \&script_state;
}

END {
    __PACKAGE__->store;
}

1;

__END__

=head1 NAME

Script::State - Keep script local variables

=head1 SYNOPSIS

    #!perl
    use Script::State;

    script_state my $count = 0; # set to last value if exists
    say $count++;

    # automatically write $count's current value to external file
    # to be read at next script execution

=head1 FUNCTIONS/METHODS

=over 4

=item script_state my $variable = $default;

Keep this variable's state after script execution.

=item Script::State->store;

Explicitly store current state. This is called in END block.

=back

=head1 DESCRIPTION

Script::State stores local variables to file after script execution.
Values of scalar variables with C<script_state> are stored in another file,
and the values are automatically loaded when script is executed at next time.

=head1 HOW THIS WORKS

Script::State stores variable states to file at same directory of script ($0).
For example, if $0 eq 'foo/bar.pl', filename containing state is 'foo/.bar.pl.pl'.

When Script::State is import()ed, it will load previous state from the state file,
and at the time script_state() is called, bind corresponding value to the variable.

When Script::State's END block is entered, this stores current variable values
to the state file.

=head1 CAVEATS

This modules currently uses Data::Dumper::Dump and eval() to store/load state, maybe unsafe.

This modules currently does not lock state files.

=head1 AUTHOR

motemen E<lt>motemen {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
