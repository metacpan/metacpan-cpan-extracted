package Sub::Exception;
use strict;
use warnings;

our $VERSION = '0.01';

sub import {
    my ($class, %args) = @_;

    my $caller = caller;

    while (my ($fn, $handler) = each %args) {
        $class->export(
            name          => $fn,
            error_handler => $handler,
            package       => $caller,
        );
    }
}

sub export {
    my ($class, %args) = @_;

    my $name          = $args{name};
    my $error_handler = $args{error_handler},
    my $pkg           = $args{package};

    no strict 'refs';
    *{"$pkg\::$name"} = sub (&) {
        my ($sub) = @_;

        eval {
            $sub->();
        };
        if ($@) {
            $error_handler->($_ = $@);
        }
    };
}

1;

__END__

=for stopwords Str

=head1 NAME

Sub::Exception - Code block with exception handler.

=head1 SYNOPSIS

Usually, this module acts in use phase:

    use Redis;
    use Sub::Exception redis_cmds => sub { MyException->throw($_) };

    # when some exception occurred in this block, exception MyException threw.
    redis_cmds {
        my $redis = Redis->new;
        
        $redis->multi;
        ... # redis commands
        $redis->exec;
    };

Optionally have class methods exporting code block to specified package.

    use Sub::Exception;
    
    Sub::Exception->export(
        name          => 'redis_cmds',
        error_handler => sub { MyException->throw($_) },
        package       => 'Target::Package',
    );

=head1 DESCRIPTION

Sub::Exception is code block generator that have own exception handler.

=head1 IMPORT FUNCTION

    use Sub::Exception %name_handler_pairs;

This is main usage of this module. You can set multiple sub name and error handler pairs at once.

    use Sub::Exception
        database_cmds => sub { die sprintf 'DB Error: %s', $_ },
        redis_cmds    => sub { die sprintf 'Redis Error: %s', $_ };

Above code is export two subs: C<database_cmds> and C<redis_cmds> into current package.
And these subs has own error handlers.

    database_cmd {
        # some database functions
    };

Exceptions in this code block is caught by its error handler:

    sub { die sprintf 'DB Error: %s', $_ }

So all exceptions wraps 'DB Error: ' prefix string and re-throw it.

=head1 CLASS METHODS

=head2 export( name => 'Str', error_handler => 'CodeRef', package => 'Str' )

    Sub::Exception->export(
        name          => 'redis_cmds',
        error_handler => sub { MyException->throw($_) },
        package       => 'Target::Package',
    );

Another way to export code blocks. 

    use Sub::Exception func => sub { ... };

is equivalent to:

    use Sub::Exception;
    Sub::Exception->export(
        name          => 'func',
        error_handler => sub { ... },
        package       => __PACKAGE__,
    );

This method is a bit verbosity but it's possible to export functions to any packages.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 KAYAC Inc. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

