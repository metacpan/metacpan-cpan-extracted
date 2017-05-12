package Mojolicious::Plugin::CustomLog;

$Mojolicious::Plugin::CustomLog::VERSION = '0.06';

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util 'encode';
use Fcntl ':flock';

my $PATH = +{};
my $MODE;

sub register {
    my $self = shift;
    my ($app, $config) = @_;

    $MODE = $app->mode;

    while ( my ($key, $value) = each(%{$config->{path}}) ) {
        my $file = $app->home->rel_file($value . "_" . $MODE . ".log");
        $PATH->{$key} = $file;
    }

    # attach log instance to $app->clog
    # if there is no helper name provided
    $config->{helper} ||= 'clog';
    $app->attr("_clog", sub { return $self; });
    $app->helper(
        $config->{helper} => sub {
            my $self = shift;
            return $self->app->_clog;
        }
    );

    # export alias of this logger
    #
    # alias is very useful when $app can not be easily accessed
    # for example, using $Alias::CLog->debug instead of $app->clog
    #
    # however, this will currupt other namespace
    # so please use this with caution
    if ($config->{alias}) {
        no strict 'refs';
        *{"$config->{alias}::CLog"} = \$self;
    }
}

sub debug {
    my $self = shift;
    my $target = shift;
    my @contents = @_;
    $self->_out($target, 'debug', @contents);
}

sub info {
    my $self = shift;
    my $target = shift;
    my @contents = @_;
    $self->_out($target, 'info', @contents);
}

sub warn {
    my $self = shift;
    my $target = shift;
    my @contents = @_;
    $self->_out($target, 'warn', @contents);
}

sub error {
    my $self = shift;
    my $target = shift;
    my @contents = @_;
    $self->_out($target, 'error', @contents);
}

sub fatal {
    my $self = shift;
    my $target = shift;
    my @contents = @_;
    $self->_out($target, 'fatal', @contents);
}

sub _out {
    my $self = shift;
    my $target = shift;
    my $level = shift;
    my @contents = @_;

    my $path   = $PATH->{$target};

    if (!$path) {
        die "Undefined target: $target. path: $path";
    }

    my $log = join("\t", @contents);

    # remove line break for contents
    # there should always be one line per output
    $log =~ s/\n//g;

    $self->_append($path, $self->_format($level, $log));
}

sub _append {
    my $self = shift;
    my ($path, $log) = @_;

    $path .= "." . _get_local_date();
    open HANDLE, ">>", $path or die "Can not open file $path";

    flock HANDLE, LOCK_EX;
    HANDLE->print(encode('UTF-8', $log)) or die "Can't write to log: $!";
    flock HANDLE, LOCK_UN;

    close HANDLE;
}

sub _format {
    my $self = shift;
    return'[' . localtime . '] [' . shift . '] ' . shift . "\n";
}

sub _get_local_date {
    my ($second, $minute, $hour, $day, $month, $year, $weekday, $yesterday, $is_dst) = localtime;
    return sprintf("%04d%02d%02d", $year + 1900, $month + 1, $day);
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::CustomLog - A custom logger that can output log by date and type

=head1 VERSION

version 0.06

=head1 SYNOPSIS

Provides custom log utilities that can output log by date and type

    use Mojolicious::Plugin::CustomLog;

    sub startup {
        my $self = shift;

        $self->plugin('CustomLog', {
                "path" => {
                    "test"   => "log/test"   # relative to home directory of app
                    "check"  => "log/check"
                },
                "helper" => "mylog",
                "alias"  => "Global"
            });

        # using app helper
        $self->mylog->debug('test',  "this is test log");

        # using alias
        Global::CLog->error('check', "this is error log");
    }

=head1 CONFIGURATION

=head2 CONFIGURE YOUR OWN LOGGER

=over 3

=item 'path'        should contain at least a key value pair that identifies the path of the log

=item 'helper'      the name of the helper to associate with the logger (default: clog)

=item 'alias'       if provided, an alias of CustomLog object will be created

=back

There should be at least one log defined. Other configs are optional.

=head1 METHODS/HELPERS

A helper is created with a name you specified (or 'clog' by default).

=head1 AUTHOR

Jingxuan Wang, C<< <lxem.wjx@gmail.com> >>

=head1 BUGS/CONTRIBUTING

Please report any bugs or feature requests to through the web interface at L<https://github.com/jingxuanwang/Mojolicious-Plugin-CustomLog/issues>.
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from L<https://github.com/jingxuanwang/Mojolicious-Plugin-CustomLog/>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016- Jingxuan Wang.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
