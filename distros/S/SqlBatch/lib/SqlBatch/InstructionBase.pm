package SqlBatch::InstructionBase;

# ABSTRACT: Base class for an instruction

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;

sub new {
    my ($class,$config,$content,%args)=@_;

    my $self = {
	_configuration => $config,
	arguments      => \%args,
	content        => $content,
	runstate       => undef,
	addresss       => undef,
   };

    $self = bless $self, $class;
    return $self;    
}

sub show_warning {
    my $self = shift;
    my $text = shift;

    say STDERR "WARNING: $text";
}

sub show_error {
    my $self = shift;
    my $text = shift;

    say STDERR "ERROR: $text";
}

sub run_if_tags {
    my $self = shift;

    return %{$self->{arguments}->{run_if_tags} // {}}
}

sub run_not_if_tags {
    my $self = shift;

    return %{$self->{arguments}->{run_not_if_tags} // {}}
}

sub state_dump {
    my $self = shift;

    my @public_keys = map { ! /^_/} keys %$self;
    my %public      = map { $_ => $self->{$_}} @public_keys;

    return \%public;  
}

sub configuration {
    my $self = shift;

    return $self->{_configuration};
}

sub argument {
    my $self = shift;
    my $name = shift;

    return $self->{arguments}->{$name};
}

sub address {
    my $self = shift;

    my $new = shift;
    if (defined $new) {
	croak "Instruction address is immutable"
	    if defined $self->{address};
	$self->{address} = $new;
    }
    return $self->{address};
}

sub content {
    my $self = shift;

    return $self->{content};
}

sub runstate {
    my $self = shift;
    my $new  = shift;

    if (defined $new) {
	croak "Reference to instruction runstate is immutable"
	    if defined $self->{runstate};

	$self->{runstate} = $new;
    } 
    
    return $self->{runstate};
}

sub databasehandle {
    my $self = shift;
    my $new  = shift;

    if (defined $new) {
	croak "Reference to instruction database is immutable"
	    if defined $self->{_databasehandle};

	$self->{_databasehandle} = $new;
    } 

    return $self->{_databasehandle};
}

sub run {
    croak("Abstract methode");
}

1;

__END__
    
=head1 NAME

SqlBatch::InstructionBase

=head1 DESCRIPTION

Base class for a sqlbatch instruction

=head1 METHODS

=over

=item B<address>

Returns address number of instruction in the execution plan

=item B<argument($argname)>

Returns the value of a given instruction argument

=item B<content>

Returns the value of the instruction's content area

=item B<databasehandle>

Returns a valid DBI database-handle. 

Transaction commit is either done by DBI or sqlbatch on that handle and it's session.

=item B<show_warning($text)>

Shows a warning text.

=item B<show_error($text)>

Shows a error text.

=item B<state_dump>

Returns a HASH-ref to HASH containing the (public) state of the instruction

=item B<configuration>

Reference to given L<SqlBatch::Configuration> object

=item B<run>

Abstract method to be overridden in a PERL-instruction

=item B<run_if_tags> 

HASH-ref to tags required for execution of this instruction.

=item B<run_not_if_tags>

HASH-ref to tags required for preventing execution of this instruction.

=item B<runstate>

Reference to a L<SqlBatch::RunState>-object

The runstate information are imported from an earlier instruction.
After finishing this instruction the public values of that object will be copied to the next instructions runstate.

=back

=head1 EXAMPLE OF USAGE

In this is example we execute a PERL-instruction:

    --PERL-- -class=MyPerlInstruction -special="Special value"
    My content
    --END--

The code for an PERL-instruction can look like:

    package MyPerlInstruction;

    use v5.16;
    use strict;
    use warnings;
    use utf8;

    use Carp;
    use parent 'SqlBatch::InstructionBase';

    sub new {
        my ($class,$config,$content,%args) = @_;

        my $self = SqlBatch::InstructionBase->new($config,$content,%args);

        $self = bless $self, $class;
        return $self;    
    }

    sub run {
        my $self = shift;

        my $verbosity = $self->configuration->verbosity;
        my $content   = $self->content;
        my $self->databasehandle    

        say "Running Perl instruction module SqlBatch::MyPerlInstruction" if $verbosity > 1;

        # Get a given instruction argumment
        my $special = $self->argument('special');

        # Time for some action
        eval {
            say "The special argument: ".$special;
            say "Instruction content: ".$content;

	    # Run something againt the database
	    my $rv = $dbh->...

	    # And store the returnvalue
	    $self->runstate->_returnvalue($rv);
            ...
        };
        if($@) {
            # Handle errors
	    $self->runstate->_error($@);
	    self->show_error("Failed running instruction: ".Dumper($self->state_dump));

            # Continue dying
	    croak($@);
        }
    }

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
