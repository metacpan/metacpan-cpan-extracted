package Redis::AOF::Tail::File;

use 5.008008;
use strict;
use warnings;
use File::Tail::Lite;

our $VERSION = '0.06';

sub new {
    my $pkg  = shift;
    my $self = {@_};
    bless $self, $pkg;

    return 0 unless -e $self->{aof_filename};

    $self->{ARRAY_REDIS_AOF} = ();

    if ( $self->{seekpos} ) {
        $self->{FILE_TAIL_FH} = new File::Tail::Lite(
            filename => $self->{aof_filename},
            seekpos  => $self->{seekpos}
        );
    }
    else {
        $self->{FILE_TAIL_FH} = $self->{FILE_TAIL_FH} = new File::Tail::Lite(
            filename => $self->{aof_filename},
            seekpos  => 'start'
        );
    }
    return $self;
}

sub read_command {
    my $self = shift;
    return 0 unless $self->{FILE_TAIL_FH};

    while ( my ( $pos, $line ) = $self->{FILE_TAIL_FH}->readline() ) {
        $line =~ s/\s//g;
        next if length($line) == 0;
        push @{ $self->{ARRAY_REDIS_AOF} }, $line;
        while ( defined ${ $self->{ARRAY_REDIS_AOF} }[0]
            and ${ $self->{ARRAY_REDIS_AOF} }[0] !~ /^\*\d/ )
        {
            shift @{ $self->{ARRAY_REDIS_AOF} };
        }
        my ($cmd_num) = ${ $self->{ARRAY_REDIS_AOF} }[0] =~ /^\*(\d{1,2})/
          if ${ $self->{ARRAY_REDIS_AOF} }[0];

        next
          if ( !$cmd_num
            or scalar @{ $self->{ARRAY_REDIS_AOF} } < $cmd_num * 2 + 1 )
          ;    # Wait for the complete command

        shift @{ $self->{ARRAY_REDIS_AOF} };
        my $cmd = "";
        for ( 1 .. $cmd_num ) {
            shift @{ $self->{ARRAY_REDIS_AOF} };
            $cmd .= shift @{ $self->{ARRAY_REDIS_AOF} };
            $cmd .= ' ';
        }
        $cmd = substr( $cmd, 0, -1 );
        return ( $pos, $cmd );
    }
}

1;
__END__

=head1 NAME

Redis::AOF::Tail::File - Read redis aof file in realtime

=head1 SYNOPSIS

  use Redis::AOF::Tail::File;
  
  my $aof_file = "/var/redis/appendonly.aof";
  my $redis_aof = Redis::AOF::Tail::File->new(aof_filename => $aof_file);
  while (my $cmd = $redis_aof->read_command)
  {
    print "[$cmd]\n";
  }

=head1 DESCRIPTION

This extension can be used for synchronous data asynchronously from redis to MySQL.
Maybe you can code like below.

  use DBI;
  use Redis::AOF::Tail::File;
  use Storable qw(retrieve store);
  
  # variables in this comment should be defined
  # $data_source, $username, $auth, \%attr, 
  # some_func_translate_redis_command_to_sql()
  
  my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
  my $aof_file       = "/var/redis/appendonly.aof";
  my $seek_stor_file = "/var/redis/seek_stor_file";
  my $aof_seek_pos = 'eof';
  $aof_seek_pos = ${retrieve $seek_stor_file} if -s $seek_stor_file;

  my $redis_aof = Redis::AOF::Tail::File->new(aof_filename => $aof_file, seekpos => $aof_seek_pos);
  while (my ($pos, $cmd) = $redis_aof->read_command)
  {
    my $sql = some_func_translate_redis_command_to_sql($cmd);
    store \$pos, $seek_stor_file if $dbh->do($sql);
  }

=head1 METHODS

=head2 new()

There are two forms of new().

1.Normal form. 

my $redis_aof = Redis::AOF::Tail::File->new(aof_filename => $aof_file);

2.Read from the seekpos.

my $redis_aof = Redis::AOF::Tail::File->new(aof_filename => $aof_file, seekpos => $aof_seek_pos);



=head2 read_command()

There are two forms of this method is called.

1. my $cmd = $redis_aof->read_command()

you got the redis command in $cmd.

2. my ($pos, $cmd) = $redis_aof->read_command().

you got redis command in $cmd, and read position in $pos.
	

=head1 EXPORT

None by default.


=head1 SEE ALSO

L<Redis::Term>, L<Redis>

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
