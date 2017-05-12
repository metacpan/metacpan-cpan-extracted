package P5U::Command::cttail;

use 5.010;
use strict;
use utf8;
use P5U -command;

BEGIN {
	$P5U::Command::cttail::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::cttail::VERSION   = '0.001';
};

use constant TAIL_LOG => "http://metabase.cpantesters.org/tail/log.txt";

use constant {
	abstract      => q[grep through the last 1000 cpan testers reports],
	command_names => q[cttail],
	usage_desc    => q[%c cttail %o],
};

sub opt_spec
{
	return (
		[ "regexp|r=s"   => "search entire line by regexp" ],
		[ "author|a=s"   => "search for author cpan id" ],
		[ "dist|d=s"     => "search for distribution name" ],
		[ "version|v=s"  => "search for version number" ],
		[ "grade|g=s"    => "search for grade" ],
		[ "reporter|t=s" => "search for reporter by regexp" ],
		[ "platform|p=s" => "search for platform by regexp" ],
		[ "format|F=s"   => "Text::sprintfn-compatible output format" ],
	);
}

sub execute
{
	require LWP::Simple;
	require Text::sprintfn;
	
	my ($self, $opt, $args) = @_;
	
	my $format = $opt->format //
		q{%(grade)s: %(filename)s %(perlversion)s %(platform)s (%(reporter)s)};
	
	my @log = split /\r?\n/, LWP::Simple::get(TAIL_LOG);
	for my $line (@log)
	{
		my $data = $self->_parse_line($line);
		
		next if (defined $opt->regexp   and $line !~ m/${\ $opt->regexp}/i);
		next if (defined $opt->author   and lc $data->{author}  ne lc $opt->author);
		next if (defined $opt->dist     and lc $data->{dist}    ne lc $opt->dist);
		next if (defined $opt->version  and lc $data->{version} ne lc $opt->version);
		next if (defined $opt->grade    and lc $data->{grade}   ne lc $opt->grade);
		next if (defined $opt->reporter and $data->{reporter} !~ m/${\ $opt->reporter}/i);
		next if (defined $opt->platform and $data->{platform} !~ m/${\ $opt->platform}/i);
		
		Text::sprintfn::printfn("$format\n", $data);
	}
}

sub _parse_line
{
	my ($self, $line) = @_;
	chomp $line;
	
	return unless $line =~ m{
		^
		\[(?P<submitted> .+? )\]
		\s*
		\[(?P<reporter> .+? )\]
		\s*
		\[(?P<grade> .+? )\]
		\s*
		\[(?P<filename> .+? )\]
		\s*
		\[(?P<platform> .+? )\]
		\s*
		\[(?P<perlversion> .+? )\]
		\s*
		\[(?P<uuid> .+? )\]
		\s*
		\[(?P<accepted> .+? )\]
	}x;
	
	my %P = %-;
	
	%P = (%P, %-) if $P{filename}[0] =~ m{
		^
		(?P<author> .+? )
		\/
		(?P<dist> .+? )
		\-
		(?P<version> [vV]?[0-9][0-9_\.]*(?:-TRIAL)? )
		\.
		(?P<suffix> tar\.gz | tar\.bz2? | tgz | tbz2? | zip )
		$
	}x;

	$P{$_} = $P{$_}[0] for grep ref($P{$_}), keys %P;
	$P{grade} = uc $P{grade};
	return \%P;
}


1;

__END__

=head1 NAME

P5U::Command::cttail - grep through the last 1000 cpan testers reports

=head1 SYNOPSIS

 $ p5u cttail --author=TOBYINK

 $ p5u cttail --reporter=TOBYINK

 $ p5u cttail -d Moose -f '%(grade)s for %(perlversion)s on %(platform)s'

=head1 DESCRIPTION

Simple tool to grep L<http://metabase.cpantesters.org/tail/log.txt>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U-Command-cttail>.

=head1 SEE ALSO

L<p5u>, L<P5U::Command::Testers>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

