=head1 NAME

Synapse::CLI::Config - configure and manage your application objects in a terminal


=head1 About Synapse's Open Telephony Toolkit

L<Synapse::CLI::Config> is a part of Synapse's Wholesale Open Telephony
Toolkit.

As we are refactoring our codebase, we at Synapse have decided to release a
substantial portion of our code under the GPL. We hope that as a developer, you
will find it as useful as we have found open source and CPAN to be of use to
us.


=head1 What is L<Synapse::CLI::Config> all about

We strongly believe that prior to building graphical front ends, it is
necessary to build a robust and reliable command line interface in order to
configure software packages.

The goal of this module is to provide something that will allow you to interact
with your application objects and classes using the command line, and make
object changes persistent on disk.


=head1 SYNOPSIS

Say you create a MyAPP::User object.


=head2 Step 1 

Make MyAPP::User inherit from L<Synapse::CLI::Config::Object>:

    use base qw /Synapse::CLI::Config::Object/;

Doing this means that your class will inherit L<Synapse::CLI::Config::Object> methods.


=head2 Step 2 

Write your own methods, for example in MyAPP::User, these could be something in
the lines of:

    sub password {
        my $self = shift;
        @_ and $self->{password} = shift;
        return $self->{password};
    }
    
    sub email {
        my $self = shift;
        @_ and $self->{email} = shift;
        return $self->{email};
    }


Create a simple script, say myapp-cli, which declares aliases for your objects
and calls the Synapse::CLI::Config::execute() method.

    #!/usr/bin/perl
    # this is myapp-cli. It should be installed in /usr/local/bin/myapp-cli
    use Synapse::CLI::Config;
    use YAML::XS;
    use warning;
    use strict;
    $Synapse::CLI::Config::BASE_DIR = "/etc/myapp";
    $Synapse::CLI::Config::ALIAS->{type} = 'Synapse::CLI::Config::Type';
    $Synapse::CLI::Config::ALIAS->{user} = 'MyAPP::User';
    print Dump (Synapse::CLI::Config::execute (@ARGV));


=head2 Step 3, congrats, you've built your own CLI interface!

Now let's create a user and use these fancy methods.

    # create user 'foo' with label 'Foo Bar'
    myapp-cli type user create foo "Foo Bar"
    
    # change password and email
    myapp-cli user foo email example@example.com
    myapp-cli user foo password "very hard to remember"
    
    # view result
    myapp-cli user foo show
    
    # rename foo
    myapp-cli user foo rename bar
    
    # get rid of it now
    myapp-cli user bar remove 
    

=head1 API

=cut
package Synapse::CLI::Config;
use YAML::XS;
use warnings;
use strict;


=head2 GLOBALS

=over 4

=item $Synapse::CLI::Config::VERSION - library version number

=item $Synapse::CLI::Config::BASE_DIR - points to the directory where object
configuration files live.

=item $Synapse::CLI::Config::ALIAS - alias => package name mapping.

=item @Synapse::CLI::Config::BUFFER - where execute() commands are logged prior to
flushing() everything to disk.

=back

=cut
our $VERSION  = 0.1;
our $BASE_DIR = $ENV{CLI_CONFIG_BASEDIR} || "/etc/cli-config";
our $ALIAS    = { 
    type    => 'Synapse::CLI::Config::Type',
};



=head2 Synapse::CLI::Config::base_dir()

Returns $BASE_DIR

=cut
sub base_dir {
    return $BASE_DIR;
}



=head2 Synapse::CLI::Config::debug($msg)

Debug hook. Sends messages to STDERR.

=cut
sub debug($) {
    my $msg = shift;
    print STDERR ' -- ';
    print STDERR scalar gmtime;
    print STDERR ' -- ';
    print STDERR $msg;
    print STDERR "\n";
}


=head2 Synapse::CLI::Config::parse($file)

Turns a YAML file into a Perl structure and returns it.

=cut
sub parse {
    my $file = shift;
    -e $file || return;
    open FILE, "<$file" or do {
        debug ("cannot read open $file");
        return;
    };
    my $yaml = join '', <FILE>;
    close FILE;
    return Load $yaml;
}


=head2 Synapse::CLI::Config::dump($file, $scalar)

Turns Perl $scalar (which will most often be a reference) into a YAML file.

=cut
sub dump {
    my $file = shift;
    my $obj  = shift;
    -e $file || return;
    open FILE, ">file" or do {
        debug ("cannot write open $file");
        return;
    };
    print FILE Dump $obj;
    close FILE;
}


=head2 Synapse::CLI::Config::execute (@args)

Executes command, and saves it in the corresponding file if object is changed.

For instance:

    $Synapse::CLI::Config::ALIASES->{foo} = "My::Foo";
    Synapse::CLI::Config::execute ("My::Foo", "bar", "baz");

Is like saying:

    My::Foo->new ('bar')->baz();

On the cli it should look like this:

    myapp-cli foo bar baz

=cut
sub execute {
    my $type = shift || die "usage: $0 <objType> <objid> <method> arg1 ... argN";
    
    my $package = $Synapse::CLI::Config::ALIAS->{$type} || $type;
    eval "use $package";
    
    my $name = shift;
    defined $name || die "object name unspecified";
    
    my $object = $package->new ($name) || die "$name does not exist";
    my $method = shift || die "method unspecified";
    $method =~ s/-/_/g;
    $object->can ($method) || die "no such method";
    
    my $before = YAML::XS::Dump ($object);
    my $res;
    eval { $res = $object->$method (@_) };
    $@ and die $@;
    my $after  = YAML::XS::Dump ($object);
    
    my $FORCE_SAVE   = $method . "_FORCE_SAVE";
    my $FORCE_NOSAVE = $method . "_FORCE_NOSAVE";
    
    # if $object->method_FORCE_SAVE() exists, always logs
    if ($object->can ($FORCE_SAVE)) {
        $object->__save__ ($method => @_);
    }
    
    # if $object->method_FORCE_NOSAVE() exists, never logs
    elsif ($object->can ($FORCE_NOSAVE)) {
    }
    
    # otherwise, logs only if object has changed
    else {
        $before ne $after and do { $object->__save__ ($method => @_) }
    }
    
    return $res;
}


1;


__END__

=head1 EXPORTS

none.


=head1 BUGS

Please report them to me. Patches always welcome...


=head1 AUTHOR

Jean-Michel Hiver, jhiver (at) synapse (dash) telecom (dot) com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
