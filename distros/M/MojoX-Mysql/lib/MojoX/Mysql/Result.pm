package MojoX::Mysql::Result;
use Mojo::Base -base;
use Mojo::Util qw(dumper);
use Mojo::Collection 'c';
use Mojo::Date;

sub async {
	my ($self,$sth,$dbh,$cb) = @_;
	sleep(0.01) until($sth->mysql_async_ready);
	my $counter = $sth->mysql_async_result;
	my $collection = $self->collection($sth,$cb);
	$sth->finish;
	$dbh->commit;
	$dbh->disconnect;
	return wantarray ? ($collection,$counter,$sth,$dbh) : $collection;
}

sub collection {
	my ($self,$sth,$cb) = @_;
	my $collection = c();
	my $names = $sth->{'NAME'};
	my $types = $sth->{'mysql_type_name'};
	my $nulls = $sth->{'NULLABLE'};

	while (my $ref = $sth->fetch()) {
		if(ref($names) eq 'ARRAY'){
			my %hash;
			my $count_state = -1;
			for(@{$names}){
				$count_state++;
				my $value = $ref->[$count_state];
				my $type = $types->[$count_state];
				my $null = $nulls->[$count_state];

				if($type eq 'tinyint' || $type eq 'smallint' || $type eq 'mediumint' || $type eq 'integer' || $type eq 'bigint'){
					if($null == 1 && !defined $value){
						$value = undef;
					}
					else{
						$value = int $value;
					}
				}
				elsif($type eq 'datetime' && defined $value){
					$value = Mojo::Date->new($value);
				}
				else{
					if(!$value && $null){
						$value = undef;
					}
					else{
						$value =~ s/^\s+|\s+$//g;
						utf8::decode($value) unless utf8::is_utf8($value);
					}
				}
				$hash{$_} = $value;
			}
			$self->$cb(\%hash) if(ref $cb eq 'CODE');
			push(@{$collection}, \%hash);
		}
	}
	return $collection;
}


1;

