# $Id: ActionFixture.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::ActionFixture;

use base 'Test::C2FIT::Fixture';

use strict;
use Test::C2FIT::TypeAdapter;
use Error qw( :try );

use vars qw($actor);
$actor = undef;

sub new {
    my $pkg = shift;
    return $pkg->SUPER::new( cells => undef, empty => undef, @_ );
}

sub doCells {
    my $self = shift;
    my ($cells) = @_;

    $self->{'cells'} = $cells;
    try {

        # N.B. "do_" is prepended to avoid a method collision on "check"
        my $method = "do_" . $cells->text();
        $self->$method();
      }
      otherwise {
        my $e = shift;
        $self->exception( $cells, $e );
      };
}

# Actions

sub do_start {
    my $self = shift;
    my $pkg  = $self->{'cells'}->more()->text();
    $actor = $self->_createNewInstance($pkg);
}

sub do_enter {
    my $self = shift;

    throw Test::C2FIT::Exception("no actor") unless defined($actor);

    my $method      = $self->method();
    my $text        = $self->{'cells'}->more()->more()->text();
    my $typeAdapter = Test::C2FIT::TypeAdapter->onSetter( $actor, $method );
    $actor->$method( $typeAdapter->parse($text) );
}

sub do_press {
    my $self   = shift;
    my $method = $self->method();
    $actor->$method();
}

sub do_check {
    my $self = shift;

    throw Test::C2FIT::Exception("no actor") unless defined($actor);
    my $method = $self->method();
    my $adapter = Test::C2FIT::TypeAdapter->onMethod( $actor, $self->method() );
    $self->check( $self->{'cells'}->more()->more(), $adapter );
}

# Utility

sub method {
    my $self   = shift;
    my $method = $self->camel( $self->{'cells'}->more()->text() );
    throw Test::C2FIT::Exception("no actor") unless defined($actor);
    throw Test::C2FIT::Exception("no such method: $method on $actor\n")
      unless $actor->can($method);
    return $method;
}

1;

=pod

=head1 NAME

Test::C2FIT::ActionFixture - An action fixture interprets rows as a sequence of commands to be performed in order.

=head1 SYNOPSIS

Normally, you do not use this class directly, rather you use its name in your FIT-document.

=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/


=cut

__END__

package fit;

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

import java.lang.reflect.Method;

public class ActionFixture extends Fixture {
    protected Parse cells;
    public static Fixture actor;
    protected static Class empty[] = {};

    // Traversal ////////////////////////////////

    public void doCells(Parse cells) {
        this.cells = cells;
        try {
            Method action = getClass().getMethod(cells.text(), empty);
            action.invoke(this, empty);
        } catch (Exception e) {
            exception(cells, e);
        }
    }

    // Actions //////////////////////////////////

    public void start() throws Exception {
        actor = (Fixture)(Class.forName(cells.more.text()).newInstance());
    }

    public void enter() throws Exception {
        Method method = method(1);
        Class type = method.getParameterTypes()[0];
        String text = cells.more.more.text();
        Object args[] = {TypeAdapter.on(actor, type).parse(text)};
        method.invoke(actor, args);
    }

    public void press() throws Exception {
        method(0).invoke(actor, empty);
    }

    public void check() throws Exception {
        TypeAdapter adapter = TypeAdapter.on(actor, method(0));
        check (cells.more.more, adapter);
    }

    // Utility //////////////////////////////////

    protected Method method(int args) throws NoSuchMethodException {
        return method(camel(cells.more.text()), args);
    }

    protected Method method(String test, int args) throws NoSuchMethodException {
        Method methods[] = actor.getClass().getMethods();
        Method result = null;
        for (int i=0; i<methods.length; i++) {
            Method m = methods[i];
            if (m.getName().equals(test) && m.getParameterTypes().length == args) {
                if (result==null) {
                    result = m;
                } else {
                    throw new NoSuchMethodException("too many implementations");
                }
            }
        }
        if (result==null) {
            throw new NoSuchMethodException();
        }
        return result;
    }
}

