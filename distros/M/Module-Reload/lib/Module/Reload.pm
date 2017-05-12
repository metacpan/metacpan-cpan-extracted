package Module::Reload;
$Module::Reload::VERSION = '1.11';
use 5.006;
use strict;
use warnings;

our $Debug = 0;
our %Stat;

sub check {
    my $c=0;

    foreach my $entry (map { [ $_, $INC{$_} ] } keys %INC) {
        my($key,$file) = @$entry;

        # If the require'ing of a file failed, but was caught by eval,
        # then we end up with a value of undef in %INC. Skip those.
        next unless defined($file);

        next if $file eq $INC{"Module/Reload.pm"};  #too confusing
        local $^W = 0;
        my $mtime = (stat $file)[9];
        $Stat{$file} = $^T unless defined $Stat{$file};

        if ($Debug >= 3) {
            warn "Module::Reload: stat '$file' got $mtime >? $Stat{$file}\n";
        }

        if ($mtime > $Stat{$file}) {
            delete $INC{$key};
            eval { 
                local $SIG{__WARN__} = \&warn;
                require $key;
            };
            if ($@) {
                warn "Module::Reload: error during reload of '$key': $@\n";
            }
            elsif ($Debug) {
                if ($Debug == 1) {
                    warn "Module::Reload: process $$ reloaded '$key'\n";
                }
                if ($Debug >= 2) {
                    warn("Module::Reload: process $$ reloaded '$key' (\@INC=".
                         join(', ',@INC).")\n");
                }
            }
            ++$c;
        }
        $Stat{$file} = $mtime;
    }
    $c;
}

1;

__END__

=head1 NAME

Module::Reload - Reload %INC files when updated on disk

=head1 SYNOPSIS

  Module::Reload->check;

=head1 DESCRIPTION

When Perl pulls a file via C<require>, it stores the filename in the
global hash C<%INC>.  The next time Perl tries to C<require> the same
file, it sees the file in C<%INC> and does not reload from disk.  This
module's handler iterates over C<%INC> and reloads the file if it has
changed on disk. 

Set $Module::Reload::Debug to enable debugging output.

=head1 BUGS

A growing number of pragmas (C<base>, C<fields>, etc.) assume that
they are loaded once only.  When you reload the same file again, they
tend to become confused and break.  If you feel motivated to submit
patches for these problems, I would encourage that.

=head1 SEE ALSO

L<Module::Reload::Selective> is like this module, but lets you
control which modules will be reloaded.

L<again> provides a slightly different mechanism for reloading
changed modules, where you have to explicitly decide which modules to reload.

L<Apache2::Reload> (or L<Apache::Reload> if you're still using Apache 1).

L<perldoc require|http://perldoc.perl.org/functions/require.html>
for details of how C<require> works.

=head1 REPOSITORY

L<https://github.com/neilb/Module-Reload>

=head1 AUTHOR

Doug MacEachern & Joshua Pritikin

Now maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1997-1998 Doug MacEachern & Joshua Pritikin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

