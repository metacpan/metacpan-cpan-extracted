# Efetua conexao com o banco de dados de forma eficiente,
# simples e rapida.
# Compativel apenas com MySQL por enquanto
# By: Udlei Nattis <unattis@nattis.com>

# {type},{db},{host},{username},{passwd}
# MySQL vars: host,username,passwd,db

package NTS::SqlLink;

use vars qw($conn);
use DBI;
use strict;
use warnings FATAL => 'all';

our $VERSION = '2.0';

# Inicia conexao
sub new {
    my($self,$vars) = @_;
    my ($conn);

    $vars->{acommit} = 0 unless defined $vars->{acommit};
    $vars->{acommit} = $vars->{acommit};

    # Verifica se é mysql
    if ($vars->{type} eq "mysql") {

        # Faz conexao
        $conn = DBI->connect("DBI:$vars->{type}:$vars->{db}:$vars->{host}",
            $vars->{username},$vars->{passwd},{  AutoCommit => $vars->{acommit} })
                or die DBI::errstr;

        bless {
            conn => $conn,
            type => $vars->{type},
            error => undef,
            pre => undef,
            arows => undef,
        }, $self;
    }
}

# Recupera dados do db
sub return {
    my ($self,$q,$t) = @_;
    my (@array,@row,$row);

    # Verifica formato de dados que deve retorna
    $t = "scalar" if (!$t);

    # Prepara query
    eval { $self->{pre} = $self->{conn}->prepare($q); };

    # Verifica se conseguiu executar a query
    eval $self->{pre}->execute;
    if ($@) {
        die "\n".DBI::err.": ".DBI::errstr;
    };
    
    # Retorna em formato array
    if ($t eq "array") {
        while (@row = $self->{pre}->fetchrow_array) {
            push(@array,[ @row ]);
        }
    }

    # Retorna em formato hash
    elsif ($t eq "scalar") {
        eval { 
            while ($row = $self->{pre}->fetchrow_hashref) {
                push(@array,$row);
            }
        };
    }

    eval { $self->{pre}->finish };

    # Apaga variaveis indesejadas
    #print $q."\n";
    undef $q; undef $t;

#    print $self->{conn}->{mysql_info}."\n" if defined $self->{conn}->{mysql_info};
#    print $self->{conn}->{mysql_stat}."\n";

    # Retorna os resultados do select
    return @array;
}

# executa funcao 'do'
sub do {
    my ($self,$q) = @_;

    eval { $self->{arows} = $self->{conn}->do($q); }
        or die $q."\n".DBI::err.": ".DBI::errstr;
	
    #if (DBI::errstr) {
    #    $self->{error} = DBI::errstr;
    #    return 0;
    #}
	
    undef $q;
    
    return 1;
}

# commit
sub commit {
    my ($self) = @_;

    $self->{conn}->commit();
    
    return 1;
}

# rollback
sub rollback {
    my ($self) = @_;

    $self->{conn}->rollback();

    return 1;
}

# Adiciona quote
sub qt {
    my ($self,$buf) = @_;
    my($r);
	
    $r = $self->{conn}->quote($buf);
    $r = "''" if ($r eq "NULL");
    return $r;
}

# Desconecta do banco de dados
sub disconnect {
    my ($self) = @_;

    $self->{conn}->disconnect;

    # Apaga variaveis
    delete $self->{conn};
    delete $self->{type};
    $self = undef;
}

# Recupera numero de linhas
sub rows {
    my ($self) = @_;

    return $self->{pre}->rows;
}

# Recupera numero de linhas afetadas
sub arows {
    my ($self) = @_;

    return $self->{arows};
}

# Recupera ultima linha inserida
sub insertid {
    my ($self) = @_;

    # mysql
    #if ($self->{type} eq "mysql") { $self->{conn}->{mysql_insertid}; }
    return $self->{conn}->{mysql_insertid};
}

# Retorna self
sub self {
    my ($self,$field) = @_;

    return $self->{$field};
}

# retorn erro
#sub error {
#    my ($self) = @_;
#    return $self->{error};
#}

1;
__END__

=head1 NAME

NTS::SqlLink - Front-end module to MySQL

=head1 DESCRIPTION

MySQL easy access

=head1 SYNOPSIS

	#!/usr/bin/perl]

	use strict;
	use NTS::SqlLink;
	my(@r,$c,$q,$i);

	# Open DB
	$c = new NTS::SqlLink({
		'type'      => 'mysql',
		'db'        => 'test',
		'host'      => 'localhost',
		'username'  => 'root',
		'passwd'    => '',
	});

	# Query Insert
	$q = "INSERT INTO test (id,name) VALUES (null,'user')";
	$c->do($q); undef $q;

	# Query Select
	$q = "SELECT id,name FROM test";

	# Result
	@r = $c->return($q);
	foreach $i (@r) {
		print "ID: ".$i->{id}." - Name: ".$i->{name}."\n";
	}

	# Close DB
	$c->disconnect;

=head1 METHODS

=head2 new({type,db,host,username,passwd})

	Create a new SqlLink object.

	my $c = new NTS::SqlLink({
		'type'		=>	'mysql',
		'db'        => 'test',
		'host'      => 'localhost',
		'username'  => 'root',
		'passwd'    => '',
	});

=head2 $c->return(query)
	
	only for select

	@r = $c->return($q);
	foreach $i (@r) {
		print "ID: ".$i->{id}." - Name: ".$i->{name}."\n";
	}

=head2 $c->do(query)
	
	to insert,update,replace,etc...

	$q = "INSERT INTO test (id,name) VALUES (null,'user')";
	$c->do($q); undef $q;


=head2 $c->disconnect()

	disconnect
	
	$c->disconnect();

=head2 $c->insertid()

	return last insert id

=head2 $c->qt(string)

	AddSlashes

	$q = "INSERT INTO test (id,name) VALUES (null,'".$c->qt($user)."')";

=head1 Authors

=over

=item

    Udlei Nattis E<lt>unattis (at) nattis.comE<gt>
    http://www.nattis.com

=back

=cut
