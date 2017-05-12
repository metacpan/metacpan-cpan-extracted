# PANT::Cvs - Provide support for CVS operations

package PANT::Cvs;

use 5.008;
use strict;
use warnings;
use Carp;
use Cwd;
use XML::Writer;
use Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PANT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.02';


sub new {
    my($clsname, $writer, @rest) =@_;
    my $self = { 
	writer=>$writer,
	@rest,
    };
    bless $self, $clsname;
    return $self;
}

sub Run {
    my($self, $cmd, %args) = @_;
    my $writer = $self->{writer};
    my $cdir = ".";
    if ($args{directory}) {
	$cdir = getcwd;
	chdir($args{directory}) || Abort("Can't change to directory $args{directory}");
	
    }
    $writer->startTag('li');
    $writer->characters("Run $cmd\n");
    my $output;
    my $retval;
    if ($self->{dryrun}) {
	$output = "Output of the command $cmd would be here";
	$retval = 1;
    }
    else {
        $writer->startTag('pre');
	$cmd .= " 2>&1"; # collect stderr too
	$self->{lines} = [];
	if (open(PIPE, "$cmd |")) {
	    while(my $line = <PIPE>) {
		$writer->characters($line);
		push(@ {$self->{lines} }, $line);
	    }
	    close(PIPE);
	    $retval = $? == 0;
	}
	else {
	    $retval = 0;
	}
        $writer->endTag('pre');
    }
    $writer->characters("$cmd failed: $!") if ($retval == 0);
    $writer->endTag('li');
    do { chdir($cdir) || Abort("Can't change back to $cdir: $!"); } if ($args{directory});
    return $retval;
}

sub HasUpdate {
    my $self = shift;
    foreach my $line (@{ $self->{lines} }) {
	if ($line =~ /^\s*[UP]\s+/) { # Its a change, one out, all out.
	    return 1;
	}
    }
    return 0;
}

sub HasLocalMod {
    my $self = shift;
    foreach my $line (@{ $self->{lines} }) {
	if ($line =~ /^\s*[MA]\s+/) { # Its a change, one out, all out.
	    return 1;
	}
    }
    return 0;
}
sub HasConflict {
    my $self = shift;
    foreach my $line (@{ $self->{lines} }) {
	if ($line =~ /^\s*[C]\s+/) { # Its a conflict
	    return 1;
	}
    }
    return 0;
}

1;
__END__

=head1 NAME

PANT::Cvs - PANT support for cvs operations

=head1 SYNOPSIS

  use PANT;

  $cvs = Cvs();
  $cvs->Run("cvs update");
  if ($cvs->HasUpdates()) {
    # increment version
    # run a build etc.
  }


=head1 ABSTRACT

  This is part of a module to help construct automated build environments.
  This part is for help processing Cvs operations.

=head1 DESCRIPTION

This module is part of a set to help run automated
builds of a project and to produce a build log. This part
is designed to provide support for cvs. Most cvs operations can
be simply run as Command's from the main module, but occasionally
you want to know if something has changed. For instance you 
may not want to run an auto build if nothing has changed 
since last time.

=head1 EXPORTS

None

=head1 METHODS

=head2 new($xml);

Constructor for a test object. Requires an XML::Writer object,
which it will use for subsequent log
construction. The PANT function Cvs calls this constructor with the
current xml stream. So normally
you would call it via the accessor.

=head2 Run(command)

This command will run the given cvs command, and will collect
the output, pass it to the log stream, and analyse it too.


=head2 HasUpdate()

This is a boolean function that tells you if the last Run command
detected any updates to the archive.

=head2 HasLocalMod()

This is a boolean function that tells you if the last Run command
detected any local uncommitted updates to the the archive.

=head2 HasConflict()

This is a boolean function that tells you if the last Run command
detected any conflicts.

=head1 SEE ALSO

Makes use of XML::Writer to construct the build log.


=head1 AUTHOR

Julian Onions, E<lt>julianonions@yahoo.nospam-co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Julian Onions

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 


=cut
