package Rubyish::AttributeOld;

=head1 NAME

Rubyish::Attribute - ruby-like accessor builder: attr_accessor, attr_writer and attr_reader.

=cut

use Sub::Exporter;
Sub::Exporter::setup_exporter({ 
    exports => [qw(attr_accessor attr_writer attr_reader)],
    groups  => { default => [-all] },
});


=head1 VERSION

This document is for version 1.0

=cut

our $VERSION = "1.0";

=head1 SYNOPSIS

    #!/usr/bin/env perl
   
    use 5.010;

    use strict;
    use warnings;

    {
        package Animal;
        
        use Rubyish::Attribute; 
        # import attr_accessor, attr_writer and attr_reader

        attr_accessor "name", "color", "type"; 
        # pass a list as the only one parameter

        # then create a constructer based on hashref
        sub new {
            $class = shift;
            bless {}, $class;
        }

        1;
    }
   
    $dogy = Animal->new()->name("rock")
                  ->color("black")->type("unknown");
    # new Animal with three attribute

    say $dogy->name;  #=> rock
    say $dogy->color; #=> black
    say $dogy->type;  #=> unknown

=head1 FUNCTIONS

=head2 attr_accessor(@list)

attr_accessor provides getters double as setters.
Because all setter return instance itself, now we can manipulate object in ruby way more than ruby.

    attr_accessor qw(name color type master)
    $dogy = Animal->new()->name("lucky")->color("white")
                  ->type("unknown")->master("shelling");

Each attribute could be read by getter as showing in synopsis.

=cut

sub attr_accessor {
    no strict;

    my $make_accessor = sub {
        my $field = shift;
        return sub {
            my ($self, $arg) = @_;
            if ($arg) {
                $self->{$field} = $arg;
                $self;
            } else {
                $self->{$field};
            }
        }
    };

    for my $field (@_) {
        *{(caller)[0] . "::" . $field} = $make_accessor->($field);
    }
}

=head2 attr_reader(@list)

attr_reader create only getter for the class you call it

    attr_reader qw(name) # pass a list
    $dogy = Animal->new({name => "rock"}) # if we write initialize function in constructor
    $dogy->name()       #=> rock
    $dogy->name("jack") #=> undef (with warn msg)

=cut

sub attr_reader {
    no strict;

    my $make_reader = sub {
        my $field = shift;
        return sub {
            my ($self, $arg) = @_;
            if ($arg) {
                warn "error - $field is only reader\n";
                return; # because no writer
            } else {
                $self->{$field};
            }
        }
    };
    
    for my $field (@_) {
        *{(caller)[0] . "::" . $field} = $make_reader->($field);
    }
}

=head2 attr_writer(@list)

attr_writer create only setter for the class you call it.

    attr_writer qw(name) # pass a list
    $dogy = Animal->new()->name("lucky") # initialize and set and get instance itself
    $dogy->name("jack") #=> instance itself 
    $dogy->name         #=> undef (with warn msg)

=cut

sub attr_writer {
    no strict;

    my $make_writer = sub {
        my $field = shift;
        return sub {
            my ($self, $arg) = @_;
            if ($arg) {
                $self->{$field} = $arg;
                $self;
            } else {
                warn "error - $field is only writer\n";
                return; # because no reader 
            }
        }
    };

    for my $field (@_) {
        *{(caller)[0] . "::" . $field} = $make_writer->($field);
    }
}

=head1 DEPENDENCE

L<Sub::Exporter>

=head1 SEE ALSO

L<Sub::Exporter>, L<autobox::Core>, L<List::Rubyish>

L<http://ruby-doc.org/core-1.8.7/classes/Module.html#M000423>

L<http://chupei.pm.org/2008/11/rubyish-attribute.html> chinese introduction

=head1 AUTHOR

shelling <navyblueshellingford at gmail.com>

gugod    <gugod at gugod.org>

=head2 acknowledgement

Thanks to gugod providing testing script and leading me on the way of perl

=head1 REPOSITORY

host:       L<http://github.com/shelling/rubyish-attribute/tree/master>

checkout:   git clone git://github.com/shelling/rubyish-attribute.git

=head1 BUGS

please report bugs to <shelling at cpan.org> or <gugod at gugod.org>

=head1 COPYRIGHT & LICENCE 

Copyright © 2008 shelling, gugod, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

