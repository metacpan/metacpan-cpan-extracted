package Padre::Task::SyntaxChecker::XML;
use strict;
use warnings;

our $VERSION = '0.10';

use base 'Padre::Task::Syntax';
use XML::LibXML;

=pod

=head1 NAME

Padre::Task::SyntaxChecker::XML - XML document syntax-checking in the background

=head1 SYNOPSIS

  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Task::SyntaxChecker::XML->new();
  $task->schedule;

  my $task2 = Padre::Task::SyntaxChecker::XML->new(
    text          => Padre::Documents->current->text_get,
    filename      => Padre::Documents->current->editor->{Document}->filename,
    on_finish     => sub { my $task = shift; ... },
  );
  $task2->schedule;

=head1 DESCRIPTION

This class implements syntax checking of XML documents in
the background. It inherits from L<Padre::Task::Syntax>.
Please read its documentation!

=cut

=for cmt
sub run {
	my $self = shift;
	$self->_check_syntax();
	return 1;
}
=cut

sub _valid {
	my $base_uri = shift;
	my $text = shift;

	my $validator = XML::LibXML->new();
	$validator->validation(0);
	$validator->line_numbers(1);
	$validator->base_uri($base_uri);
	$validator->load_ext_dtd(1);
	$validator->expand_entities(1);

	my $doc = '';
	eval {
		$doc = $validator->parse_string($text , $base_uri );
	};

	if ($@) {
		# parser error
		return _parse_msg( $@, $base_uri );
	}
	else {
		if ( $doc->internalSubset() ) {
			$validator->validation(1);
			eval {
				$doc = $validator->parse_string( $text, $base_uri );
			};
			if ($@) {
				# validation error
				return _parse_msg( $@, $base_uri );
			}
			else {
				return [];
			}
		}
		else {
			 return [];
		}
	}

}

sub _check_syntax {
	my $self = shift;

	my $base_uri = $self->{filename};

	$self->{syntax_check} = _valid ($base_uri, $self->{text});

	return;
}

sub _parse_msg {
	my ( $error, $base_uri ) = @_;

	$error =~ s/${base_uri}:/:/g;
	$error =~ s/\sat\s.+?LibXML.pm\sline.+//go;

	my @messages = split( /\n:/, $error );

	my $issues = [];

	my $m = shift @messages;

	if ( $m =~ m/^:(\d+):\s+(.+)/o ) {
		push @{$issues}, { msg => $2, line => $1, severity => 'E', desc => '' };
	}
	else {
		push @{$issues}, { msg => $m, line => $error, severity => 'E', desc => '' };
	}

	foreach my $m (@messages) {
		$m =~ m/^(\d+):\s+(.+)/o;
		push @{$issues}, { msg => $2, line => $1, severity => 'E', desc => '' };
	}

	return $issues;
}

sub syntax {
	my $self = shift;
	my $text = shift;
	if (not $self->{filename}) {
		print "error - no filename\n";
	}
	my $base_uri = $self->{filename};

	return _valid($base_uri, $text);
}
1;

__END__

=head1 SEE ALSO

This class inherits from L<Padre::Task::Syntax> which
in turn is a L<Padre::Task> and its instances can be scheduled
using L<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Heiko Jansen, C<< <heiko_jansen@web.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Heiko Jansen
Copyright 2010 Alexandr Ciornii

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

