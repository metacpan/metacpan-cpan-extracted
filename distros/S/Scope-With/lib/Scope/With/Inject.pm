package # hide from PAUSE
    Scope::With::Inject;

use strict;
use warnings;

use base qw(mysubs);

use Mouse::Meta::Class;

sub import {
    my ($class, $invocant_class) = @_;
    my $invocant;

    if ($invocant_class) {
        my @methods = Mouse::Meta::Class->initialize($invocant_class)->get_all_methods();

        for my $method (@methods) {
            my $method_name = $method->name;
            my $method_body = $method->body;

            # XXX: this is fast, but it relies on the class's
            # methods not being modified at runtime (usually the case)

            $class->SUPER::import(
                $method_name,
                sub (@) { $method_body->($invocant, @_) }
            );
        }
    } else {
        my $autoload = sub (@) {
            my ($method_name) = our $AUTOLOAD =~ /::(\w+)$/;
            return $invocant->$method_name(@_);
        };

        $class->SUPER::import(
            AUTOLOAD => $autoload,
        );
    }

    $class->SUPER::import(
        set_invocant => sub ($) { $invocant = shift }
    );
}

sub unimport {
    my $class = shift;
    $class->SUPER::unimport('set_invocant');
}

1;
