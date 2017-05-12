package Sub::Stubber::Stubs;
use strict;
use warnings;
use Class::Struct;

struct __PACKAGE__,
    ['names' => '%',
     'import_triggers' => '@',
     'env_triggers'     => '@',
     'triggered'        => '$',
     'imported_into'    => '@',
     ];
     
sub add_trigger {
    my ($self,$type,$name) = @_;
    if($type eq 'env') {
        push @{$self->env_triggers}, $name;
    } elsif ($type eq 'import') {
        push @{$self->import_triggers}, $name;
    } else {
        die("No such trigger type '$type'");
    }
}

sub add_specs {
    my ($self,@specs) = @_;
    foreach my $spec (@specs) {
        if(!ref $spec) {
            $self->names->{$spec} = undef;
        } elsif (ref $spec eq 'HASH') {
            while ( my ($name,$val) = each %$spec ) {
                $self->names->{$name} = $val;
            }
        } else {
            die ("Bad specifier '$spec'");
        }
    }
}

package Sub::Stubber;
use strict;


no strict 'refs';
no warnings 'redefine';

our %PkgCache;
our $VERSION = 0.04;


sub get_object {
    my $cls = shift;
    my $cpkg = $cls eq __PACKAGE__ ? caller : $cls;
    
    return $PkgCache{$cpkg} ||= Sub::Stubber::Stubs->new(triggered => 0);
}


sub _mk_sub_real {
    my ($cpkg,$subname,$value) = @_;
    if($subname !~ /::/) {
        $subname = $cpkg . '::' . $subname;
    }
    
    my $old_proto = prototype $subname;

    #Hope the prototype is right!
    if(defined $value && ref $value eq 'CODE') {
        *{$subname} = $value;
    } 
    elsif(defined $old_proto) {
        eval "*$subname = sub ($old_proto) { \$value };";
    }
    else {
        *{$subname} = sub { $value };
    }
}

#The next two provide some sugary API at the expense of a bleh-like 
#implementation. the functions are too simple to warrant an 
#elaborate dispatch scheme, unfortunately

sub regstubs {
    my $cls = shift;
    my $cpkg = $cls eq __PACKAGE__ ? caller : $cls;
    get_object($cpkg)->add_specs(@_);
}

sub add_trigger {
    my $cls = shift;
    my $cpkg = $cls eq __PACKAGE__ ? caller : $cls;
    get_object($cpkg)->add_trigger(@_);
}

sub mkstubs {

    my $cls = shift;
    my $cpkg = $cls eq __PACKAGE__ ? caller : $cls;
    if(!exists $PkgCache{$cpkg} && @_ == 0) {
        die("No functions registered and non provided to mkstubs()");
    }
    my $obj = $PkgCache{$cpkg};
    return if $obj->triggered();
    
    $obj->add_specs(@_);
    while (my ($subname,$subval) = each %{$obj->names}) {
        _mk_sub_real($cpkg,$subname,$subval);
    }

    $obj->triggered(1);
}

sub _import_as_base {
    my ($cls,@options) = @_;
    
    my $user_pkg = caller();
    
    my $obj = $PkgCache{$cls};
    
    if(!$obj) {
        warn("$cls has inherited from " . __PACKAGE__ . " but has not defined " .
             "any functions for stubbing");
        print Dumper(\%PkgCache);
        goto GT_EXPORTER;
    }
    
    if($obj->triggered) {
        #No need to re-generate stubs
        goto GT_EXPORTER;
    }
    
    foreach my $env (@{$obj->env_triggers}) {
        if($ENV{$env}) {
            mkstubs($cls);
            goto GT_EXPORTER;
        }
    }
    
    my $found_import_trigger = 0;
    foreach my $import (@{$obj->import_triggers}) {
        my $i = 1;
        while ($i <= $#_) {
            if($_[$i] eq $import) {
                $found_import_trigger = 1;
                splice(@_, $i, 1);
            }
            $i++;
        }
    }
    
    if($found_import_trigger) {
        mkstubs($cls);
    }
    
    
    GT_EXPORTER:
    push @{$obj->imported_into}, $user_pkg;
    
    if($cls->isa('Exporter')) {
        goto &Exporter::import;
    }
    1;
}

sub import {
    my ($cls,@options) = @_;
    
    if($cls ne __PACKAGE__) {
        goto &_import_as_base;
    }
    1;
}
1;

__END__

=head1 NAME

Sub::Stubber - Self-monkeypatch your on demand.

=head1 SYNOPSIS

    package Expensive;
    use Sub::Stubber;
    use base qw(Sub::Stubber Exporter);
    
    our @EXPORT = qw(expensive_1 expensive_2);
    Sub::Stubber->regstubs(@EXPORT);
    Sub::Stubber->add_trigger(import => '__USE_STUBS__');
    Sub::Stubber->add_trigger(env => EXPENSIVE_USE_STUBS);
    
    sub expensive_1 ($$) {
        sleep(100);
    }
    sub expensive_2 (@) {
        sleep(200);
    }
    
Meanwhile, in calling code:

    use Expensive qw(__USE_STUBS__);
    expensive_1 'foo', 'bar'; #returns immediately
    my @l;
    expensive_2 @l; #returns immediately
    
From the command line:

    EXPENSIVE_USE_STUBS=1 perl -MExpensive -e 'expensive_1 1,2'
    

=head2 DESCRIPTION

C<Sub::Stubber> allows for modules to conveniently change their containing functions
into stubs. This is useful for code which by default does expensive operations,
but which may not be desired for one-off cases, such as test environments or scripts -
or in cases where calling code knows that those functions will never need to return
anything significant.

The 'stubification' of the modules is hard. This does not attempt to merely
export stubbed functions to calling code, but will override the actual functions
with their stubbed versions, so exported,
fully qualified and intra-package calls to these
functions will all use the stubs instead.

If you would like to see a more export-oriented module, have a look at
L<Sub::Exporter>.

This module has no exports of its own, and its functionality is available via
inheritance and/or package methods:

=head3 Sub::Stubber->regstubs(...)

Register one or more sub specifications to be used in conjunction with the calling
package.


A stub specification can either be a simple name, or a hash reference.

=over

=item String

    Sub::Stubber->regstubs('foo_function');

When strings are used, a function returning undef will be triggered for it.

=item Hash Reference

    Sub::Stubber->regstubs( { 
        get_everything => 42 
    } );
    Sub::Stubber->regstubs( { 
        naive_implementation => sub { rand(10) } 
    } );

Hash reference specifications can contain one or more key-value pairs. The keys
are the function names to be replaced. The value can either be a simple scalar,
or a C<CODE> reference.

In the case of the former, the value is returned as is from the function.
In the case of the latter, the C<CODE> reference itself is interpreted to be
the replacement function. [ If you need to have a function which itself actually
returns a function, you should provide a C<CODE> reference which does just that ].

=back

Prototypes are fetched from the original function and applied to the new one.

It is also possible to specify multiple definitions in a single call, thus, the
following is perfectly valid: 

    Sub::Stubber->regstubs(
        'foo_function',
        {
            get_everything => 42,,
            naive_implementation => sub { rand(10) }
        }
    );

=head3 Sub::Stubber->add_trigger(trigger_type, trigger_name)

Modules need to know when they need to generate a trigger function.

The C<trigger_type> argument specifies what type of trigger should be added, and
C<trigger_name> is the name of that trigger.

Note that triggers only have meaning within C<Sub::Stubber>'s import function,
but should work as a standalone in a future release.

The triggers provided are:

=over

=item C<env>

Check the environment to see if a specific flag C<trigger_name> is set to true.

=item C<import>

Check arguments passed to C<import> for a token matching C<trigger_name>.

=back

=head3 Sub::Stubber->mkstubs(extra stub specifiers)

'Stubbify' the functions registered with C<regstubs> and/or additional stub
specifiers passed as arguments to C<mkstubs>.

This does not do checking on environment variables, and should be used from your
own C<import> function, if C<Sub::Stubber>'s import isn't sufficient.


=head2 INHERITING

You can inherit from C<Sub::Stubber>. Inheriting provides an import method which
works with L<Exporter>, and allows it to scan special import-time tokens and/or
environment variables specifying whether functions should be stubbified.

If you choose to inherit from this module, ensure that C<Sub::Stubber>'s  C<import>
gets called first by placing it at the beginning of your module's C<@ISA>.

Thus:

    our @ISA = qw(Sub::Stubber Exporter);

=head1 TODO

Make this module more friendly for code which doesn't like to inherit it.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2012 M. Nunberg

You may use and distribute this software under the same terms and conditions as
Perl itself.
