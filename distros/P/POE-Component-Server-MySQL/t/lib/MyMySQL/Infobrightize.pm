package MyMySQL::Infobrightize;

use MooseX::MethodAttributes::Role;

use Data::Dumper;
use SQL::Translator;
use DBI;

sub infobrightize : Regexp('qr{(INFOBRIGHTIZE\(('|"|)(.*)('|")\))}io') { #'
   my ($self, $query, @placeholders) = @_;

   unless (defined $self->local_dbh) {
      $self->send_error('Local dbh not defined !');
      return;
   }

   my $table_name = $placeholders[2];
   my $db_name;
      
   ($db_name, $table_name) = split (/\./, $table_name) if $table_name =~ /(.*)\.(.*)/;

   unless ($db_name) {
     $db_name = $self->database;
   }
   
   print 'infobrightize '.$db_name.".".$table_name."\n";
   
	my $sth = $self->local_dbh->prepare("show create table ${db_name}.${table_name}");
	$sth->execute();
	
   if ($DBI::err) {
		$self->send_error($DBI::errstr);
		return;
   }
	
   my @array = $sth->fetchrow_array();

   my $create_table = $array[1].";";
   $create_table =~  s/`//g;
   
   my $t = SQL::Translator->new(        
      show_warnings     => 1,
      no_comments       => 1,      
      quote_table_names => 0,
      quote_field_names => 0,
      parser            => 'MySQL',
      producer          => 'MySQL',
   );
   
   $t->filters( \&filter) or die $t->error;

   my @creates = $t->translate( \$create_table );
   $create_table = $creates[1];
      
   if ($db_name) {
      $self->local_dbh->do("use $db_name");
   }
   
   $self->local_dbh->do("drop table if exists ${db_name}.${table_name}_ib");
   if ($DBI::err) {
		$self->send_error($DBI::errstr);
		return;
   }
   
#   print $create_table."\n";
   
   $self->local_dbh->do($create_table);
   if ($DBI::err) {
		$self->send_error($DBI::errstr);
		return;
   }
   
   my $filename = time.$$;
   
   $self->local_dbh->do('
      select *
      into outfile \'/tmp/'.${filename}.'.dat\'
      fields terminated by \'~\' enclosed by \'\'
      lines terminated by \'\n\'
      from '.$db_name.'.'.$table_name.';
   ');
   if ($DBI::err) {
		$self->send_error($DBI::errstr);
		return;
   }
   
   $self->local_dbh->do("
      load data infile '/tmp/${filename}.dat'
      into table ".$db_name.'.'.$table_name."_ib
      fields terminated by '~' 
      enclosed by 'NULL';
   ");
   if ($DBI::err) {
		$self->send_error($DBI::errstr);
		return;
   }
		
	my $fortune = `fortune -n=60`;
	chomp($fortune);
	
	$fortune =~ s/\n//g;
	$fortune =~ s/\r//g;
	
   $self->send_results(
      ['fortune'],
      [[$fortune]]
   );
   
   unlink ('/tmp/'.$filename.'.dat');
   
   print "OK \n";
}

sub filter {        
   my $schema = shift;

   for my $table ( $schema->get_tables ) {
            
      foreach my $name ($table->get_constraints) {
         $table->drop_constraint($name);
      }
      
      foreach my $name ($table->get_indices) {
         $table->drop_index($name);
      }
      
      $table->name($table->name.'_ib');      
      
      $table->{'options'} = undef;
      
      $table->options((
         { 'ENGINE'        => 'brighthouse' },
      ));

   }

}

1;
