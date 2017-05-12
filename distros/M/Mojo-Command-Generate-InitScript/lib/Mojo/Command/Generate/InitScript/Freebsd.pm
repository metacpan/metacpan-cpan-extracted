package Mojo::Command::Generate::InitScript::Freebsd;

use warnings;
use strict;
use File::Spec;

#use base 'Mojo::Command::Generate::InitScript::Base';
use base 'Mojo::Command';
use Getopt::Long 'GetOptions';
use File::Spec;
use IO::File;

__PACKAGE__->attr(usage => <<"EOF");
FreeBSD related initscript options:
    --before <applist>         Defines services which 
                               should start after this initscript
                               for example: --before nginx
    --requre <applist>         Defines services which
                               should be started before this initscript
                               for example: --requre postgresql
EOF

sub run
{
	my ( $self, $opt ) = @_;

	$opt->{'before'}  = [];
	$opt->{'require'} = [];

	GetOptions($opt,
		'before=s{,}', 'require=s{,}',
	);

	my $rc_file = $opt->{'deploy'}
				? '/usr/local/etc/rc.d/'. $opt->{'name'}
				: File::Spec->join($opt->{'output'}, $opt->{'name'});
	$self->render_to_file( 'initscript', $rc_file, $opt );
	$self->chmod_file( $rc_file, 0755 );

	# update /etc/rc.conf
	$self->update_rc_conf( $opt->{'name'} ) if $opt->{'deploy'};
}

sub update_rc_conf
{
	my ( $self, $name ) = @_;

	my $fh = IO::File->new();
	$fh->open('/etc/rc.conf', '+<') or die qq{Can't open /etc/rc.conf\n};
	my $current_pos = 0;
	my @lines = ();
	my $read_lines = 0;
	my $update_from_pos = undef;
	my $already_done = 0;
	while ( my $line = $fh->getline )
	{
		chomp $line;
		if ( $read_lines )
		{
			push @lines, $line;
			next;
		}
		if ( $line =~ m/^\Q$name\E_enable="(.*?)"$/i )
		{
			if ( $1 =~ /^yes$/i )
			{
				$already_done = 1;
				last;
			}
			$update_from_pos = $current_pos;
			$read_lines = 1;
		}
		$current_pos = $fh->tell;
	}

	if ( ! $already_done )
	{
		if ( defined $update_from_pos )
		{
			$fh->seek( $update_from_pos, 0 );
		}
		$fh->print("\n") if $fh->eof;
		$fh->print($name, '_enable="YES"', "\n");
		if ( @lines )
		{
			$fh->print( join("\n", @lines) );
		}
		$fh->truncate( $fh->tell );
	}
	close $fh;
}

1;
__DATA__
@@ initscript
% my $opt = shift;
% my $name = $opt->{'name'};
#!/bin/sh
# PROVIDE: <%= $name %>
% if ( @{ $opt->{'before'} } )
% {
# BEFORE: <%= join(' ', @{ $opt->{'before'} }) %>
% }
# REQUIRE: NETWORKING<%= @{ $opt->{'require'} } ? ' '.join(' ', @{ $opt->{'require'} }) : '' %>
# KEYWORD: shutdown

. /etc/rc.subr

name="<%= $name %>"

rcvar=`set_rcvar`

load_rc_config $name

: ${<%= $name %>_enable="NO"}
: ${<%= $name %>_pidfile="/var/tmp/<%= $name %>.pid"}
: ${<%= $name %>_mode="daemon_prefork"}
: ${<%= $name %>_args=""}
: ${<%= $name %>_user="nobody"}

command="<%= $opt->{'app_script'} %>"
extra_commands="reload"
pidfile="${<%= $name %>_pidfile}"
sig_reload="USR1"
command_args="${<%= $name %>_mode} --daemonize --pid ${<%= $name %>_pidfile} --user ${<%= $name %>_user} ${<%= $name %>_args}"
procname="perl"

run_rc_command "$1"

__END__

=head1 NAME

Mojo::Command::Generate::InitScript::Freebsd - Initscript generator for FreeBSD

=head1 SYNOPSYS

	$ ./mojo_app.pl generate help init_script freebsd
	usage: ./mojo_app.pl generate init_script target_os [OPTIONS]

	These options are available:
		--output <folder>   Set folder to output initscripts
		--deploy            Deploy initscripts into OS
							Either --deploy or --output=dist should be specified

		--name <name>       Ovewrite name which is used for initscript filename(s)

	FreeBSD related initscript options:
		--before <applist>         Defines services which
								   should start after this initscript
								   for example: --before nginx
		--requre <applist>         Defines services which
								   should be started before this initscript
								   for example: --requre postgresql

=cut
