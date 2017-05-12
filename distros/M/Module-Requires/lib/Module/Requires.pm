package Module::Requires;
use strict;
use warnings;
our $VERSION = '0.03';

use Carp;

sub import {
    my($class, @args) = @_;
    my $is_autoload = (@args && $args[0] eq '-autoload') ? shift @args : undef;

    my $caller = caller(0);
    my $target = $is_autoload ? $caller : join '::', __PACKAGE__, '_load_tmp_', $caller;

    my @errors;
    my $i = 0;
    my $len = scalar(@args);
    my @imports;
 LOOP:
    while ($len > $i) {
        # prepare args
        my $name = $args[$i++];
        my $val  = $args[$i++];
        my $import;
        my $version;
        if ($len > $i-1 && $val =~ /^[0-9]+(?:\.[0-9]+)*$/) {
            # simple version
            $version = $val;
        } elsif (ref($val) eq 'ARRAY') {
            # detail version
            $version = $val;
        } elsif (ref($val) eq 'HASH') {
            # autoload
            unless ($is_autoload) {
                push @errors, "$name is unloaded because -autoload an option is lacking.";
                next LOOP;
            }
            $import  = $val->{import};
            $version = $val->{version};
        } elsif (ref($val)) {
            confess 'args format error';
        } else {
            $i--;
        }

        # load module
        eval qq{package $target; require $name}; ## no critic.
        if ($is_autoload) {
            push @imports, [ $name, $import ];
        }
        if (my $e = $@) {
            push @errors, "Can't load $name\n$e";
            next LOOP;
        }

        # version check
        if ($version) {
            my $mod_ver = do {
                no strict 'refs';
                ${"$name\::VERSION"};
            };
            if (defined $mod_ver) {
                if (ref($version) eq 'ARRAY') {
                    # detail version
                    if (@{ $version } % 2 == 0) {
                        my @terms;
                        my $is_error;
                        while (my($k, $v) = splice @{ $version }, 0, 2) {
                            push @terms, "$k $v";
                            if ($k eq '>') {
                                $is_error = 1 unless $mod_ver > $v;
                            } elsif ($k eq '>=') {
                                $is_error = 1 unless $mod_ver >= $v;
                            } elsif ($k eq '<') {
                                $is_error = 1 unless $mod_ver < $v;
                            } elsif ($k eq '<=') {
                                $is_error = 1 unless $mod_ver <= $v;
                            } elsif ($k eq '!=') {
                                $is_error = 1 unless $mod_ver != $v;
                            } else {
                                push @errors, "$name version check syntax error";
                                next LOOP;
                            }
                        }
                        if ($is_error) {
                            push @errors, "$name version @{[ join ' AND ', @terms ]} required--this is only version $mod_ver";
                            next LOOP;
                        }
                    } else {
                        push @errors, "$name version check syntax error";
                        next LOOP;
                    }
                } elsif ($mod_ver < $version) {
                    push @errors, "$name version $version required--this is only version $mod_ver";
                    next LOOP;
                }
            } else {
                push @errors, "$name does not define \$$name\::VERSION--version check failed";
                next LOOP;
            }
        }
    }

    # show the errors
    if (@errors) {
        confess join "\n", @errors;
    }

    # run import method
    for my $obj (@imports) {
        if (defined $obj->[1]) {
            if (@{ $obj->[1] }) {
                eval qq{package $target;\$obj->[0]->import(\@{ \$obj->[1] })}; ## no critic.
            } else {
                # same the "use Module ();", it case is do not call import method
            }
        } else {
            eval qq{package $target;\$obj->[0]->import}; ## no critic.
        }
    }
}

1;
__END__

=head1 NAME

Module::Requires - Checks to see if the module can be loaded

=head1 SYNOPSIS

more simply

  use Module::Requires 'Class::Trigger', 'Class::Accessor';
  use Class::Trigger;
  use Class::Accessor;

with version Checks

  use Module::Requires
    'Class::Trigger' => 0.13,
    'Class::Accessor';
  use Class::Trigger;
  use Class::Accessor;

detailed check of version
  # It is more than 0.10 and is except 0.12.
  use Module::Requires
    'Class::Trigger' => [ '>' => 0.10, '!=', 0.12 ],
    'Class::Accessor';
  use Class::Trigger;
  use Class::Accessor;

with autoloader

  use Module::Requires -autoload,
    'Class::Trigger', 'Class::Accessor';

with autoloader and import params

  use Module::Requires -autoload,
    'Class::Trigger' => { import => [qw/ foo bar baz /] },
    'Class::Accessor';

with autoloader and import params and version check

  use Module::Requires -autoload,
    'Class::Trigger' => {
        import  => [qw/ foo bar baz /],
        version => [ '>' => 0.10, '!=', 0.12 ],
    },
    'Class::Accessor';

=head1 DESCRIPTION

Module::Requires is Checks to see if the module can be loaded.

required modules warns of not installed if Inside of Makefile.PL With feature When specifying require module.

When writing modules, such as plugin, required modules which runs short is displayed on a user.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 THANKS TO

nekokak, lestrrat

=head1 SEE ALSO

L<Test::Requires>, idea by L<DBIx::Class::Storage::DBI::Replicated>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
