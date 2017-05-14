# $Id: Table.pm,v 1.10 1997/05/05 21:43:05 rik Exp $

BEGIN
{
  require Net::NISPlus::Object;
  require Net::NISPlus::Entry;
};

package Net::NISPlus::Table;

@ISA = qw(Net::NISPlus::Object);

sub new
{
  my($name, $path) = @_;
  my($self) = {};

  foreach (Net::NISPlus::nis_getnames($path))
  {
    my($type) = Net::NISPlus::obj_type($_);
    if (defined($type) && $type == &Net::NISPlus::TABLE_OBJ)
    {
Debug("setting full_path to $_\n");
      $self->{'full_path'} = $_;
      $self->{'cookie'} = '';
      last;
    }
  };

  return 0 unless $self->{'full_path'};

  bless $self;
}

sub create
{
  my($name) = shift;
  my($path) = shift;
  my($self) = {};
  my($ret);
  
  $ret = Net::NISPlus::nis_add($path, @_);
  if ($ret != 0)
  {
    Warning("create error: %s". niserror($ret));
    return;
  }

  foreach (Net::NISPlus::nis_getnames($path))
  {
    my($type) = Net::NISPlus::obj_type($_);
    if (defined($type) && $type == &Net::NISPlus::TABLE_OBJ)
    {
      $self->{'full_path'} = $_;
      $self->{'cookie'} = '';
      last;
    }
  };

  bless $self;
}

sub lookup
{
  my($me) = shift;
  my($ret, @res);

  my($srchstring) = $me->indexedName(shift);
  my(@colnames) = $me->colnames;

  Debug("lookup looking up $srchstring\n");
  ($ret, @res) = Net::NISPlus::entry_list($srchstring, undef);
  if ($ret != 0)
  {
    Warning("lookup $srchstring error: ", niserror($ret));
    return ();
  }
  else
  {
    foreach $entry (@res)
    {
      my($new) = {};
      foreach $field ($[..$#{@{$entry}})
      {
        $new->{$colnames[$field]} = $entry->[$field];
      }
      $entry = $new;
    }
    return @res;
  }
}

sub list
{
  my($me) = shift;
  my($retobj) = shift;
  my($ret, @res);

  ($ret, @res) = Net::NISPlus::entry_list($me->fullPath, $retobj ? $me : undef);
  if ($ret != 0)
  {
    Warning("list error: ", niserror($ret), "\n");
    return ();
  }
  else
  {
    return @res;
  }
}

=head2 colnames

colnames returns the column headings for the NIS+ table.  If called in
an array context, it returns an array containing the column names in
the order in which they appear in the table.  If called in a scalar
context, it returns a reference to a hash with keys being column names,
and values being an integer representing the column's position.

e.g.

$table = Net::NISPlus::Table('hosts.org_dir');
$cols = $table->colnames;

will end up with $cols being:

$cols->{'cname'} = 0;
$cols->{'name'} = 1;
$cols->{'addr'} = 2;
$cols->{'comment'} = 3;

and

$table = Net::NISPlus::Table('hosts.org_dir');
@cols = $table->colnames;

will end up with @cols being:

@cols = ('cname', 'name', 'addr', 'comment')

NOTE: as the colnames method behaves differently depending on what
context it is called in, it may not always behave as you expect.  For
example, the following two code fragments are not equivalent:

my($colnames) = $table->colnames;

and

my($colnames);
$colnames = $table->colnames;

The first calls colnames in an array context, and the second in a
scalar context.

=cut

sub colnames
{
  my($me) = shift;
  my($ret, $res);

  if (!defined($me->{'colnames'}))
  {
    ($ret, $res) = Net::NISPlus::table_info($me->fullPath);
    if ($ret != 0)
    {
      Warning("colnames error: ", niserror($ret), "\n");
      return ();
    }
    else
    {
      $me->{'colnamesarr'} = $res->{'ta_cols'};
      foreach ($[..$#{@{$me->{'colnamesarr'}}})
      {
        $me->{'colnameshash'}->{$me->{'colnamesarr'}->[$_]} = $_;
      }
    }
  }
  return(@{$me->{'colnamesarr'}}) if wantarray;
  return($me->{'colnameshash'});
}

sub setinfo
{
  my($me) = shift;
  my($info) = shift;
  my($ret, $res);

  ($ret, $res) = Net::NISPlus::table_setinfo($me->fullPath, $info);
  if ($ret != 0)
  {
    Warning("setinfo error: ", niserror($ret), "\n");
    return ();
  }
  else
  {
    return $res;
  }
}

sub info
{
  my($me) = shift;
  my($ret, $res);

  ($ret, $res) = Net::NISPlus::table_info($me->fullPath);
  if ($ret != 0)
  {
    Warning("info error: ", niserror($ret), "\n");
    return ();
  }
  else
  {
    return $res;
  }
}

=head2 add

Add an entry to the table.  Any columns not specified will be set to
null strings.

$table->add('key1' => 'value1', 'key2' => 'value2');

or

$table->add(['key1' => 'key1', 'key2' => 'value2'],
	['key1' => 'key3', 'key2' => 'value4'])

=cut

sub add
{
  my($ret, $res);
  my($me) = shift;

  my %info = %{info($me)};

  if (ref($_[0]) eq "ARRAY")
  {
    my($names) = shift;
    foreach $data (@_)
    {
      my(%data);
      foreach $name ($[..$#{@$names})
      {
        Debug(" setting $names->[$name] to $data->[$name]\n");
        $data{$names->[$name]} = $data->[$name];
      }
      Debug("adding\n");
      ($ret, $res) = Net::NISPlus::nis_add_entry($me->fullPath, \%data,
        $info{'owner'}, $info{'group'}, $info{'access'}, $info{'ttl'});
    }
  }
  else
  {
    my(%data) = @_;
    ($ret, $res) = Net::NISPlus::nis_add_entry($me->fullPath, \%data,
        $info{'owner'}, $info{'group'}, $info{'access'}, $info{'ttl'});
  }

  if ($ret != 0)
  {
    Warning("add error: ", niserror($ret), "\n");
    return ();
  }
  else { return $res; }
}

=head2 addinfo

Add an entry to the table, setting the info variable as we go.  Any columns
not specified will be set to null strings.

$table->addinfo([key1, key2],
  ['values' => [ 'value1', 'value2' ],
   'access' => access,
   'domain' => domain,
   'owner' => owner,
   'group' => group],
  [...])

=cut

sub addinfo
{
  my($ret, $res);
  my($me) = shift;
  my($names) = shift;

  foreach $data (@_)
  {
    my(%data);
    foreach $name ($[..$#{@$names})
    {
      Debug(" setting $names->[$name] to $data->{'values'}->[$name]\n");
      $data{$names->[$name]} = $data->{'values'}->[$name];
    }
    Debug("adding (%s)\n", $me->fullPath);
    ($ret, $res) = Net::NISPlus::nis_add_entry($me->fullPath,
      \%data,
      $data->{'owner'},
      $data->{'group'},
      $data->{'access'},
      $data->{'ttl'},
    );
  }

  if ($ret != 0)
  {
    Warning("add error: ", niserror($ret), "\n");
    return ();
  }
  else { return $res; }
}

=head2 remove

Remove a single entry from the table.  If the key/value pairs match
more that one entry, an error occurs, and no entries are removed.  Use
removem to remove multiple entries with a single command.

$table->remove({'key1' => 'value1', 'key2' => 'value2'});

or

$table->remove("[key1=value1,key2=value2]");

If you specify the table name in the indexed name form, it will be
removed and replaced with the full name determined when the table
object was created (and accessible with $table->fullName);

=cut

sub remove
{
  my($me) = shift;
  my($ret);

  my($name) = $me->indexedName(shift);
  Debug("name=|$name|\n");
  ($ret) = Net::NISPlus::nis_remove_entry($name, 0);
  if ($ret != 0)
  {
    Warning("remove error: ", niserror($ret), "\n");
    return 0;
  }
  else
  {
    return 1;
  }
}

=head2 removem

Remove one or more entries from the table. All entries which match the
key/value pairs will be removed. Use remove to remove a single entry.

$table->removem({'key1' => 'value1', 'key2' => 'value2'});

or

$table->removem("[key1=value1,key2=value2]");

If you specify the table name in the indexed name form, it will be
removed and replaced with the full name determined when the table
object was created (and accessible with $table->fullName);

=cut

sub removem
{
  my($me) = shift;
  my($ret);

  my($name) = $me->indexedName(shift);
  Debug("name=|$name|\n");
  ($ret) = Net::NISPlus::nis_remove_entry($name, 1);
  if ($ret != 0)
  {
    Warning("removem error: ", niserror($ret), "\n");
    return 0;
  }
  else
  {
    return 1;
  }
}

=head2 clear

Remove all entries from the table

$table->clear();

=cut

sub clear
{
  my($me) = @_;
  my($ret);

  ($ret) = Net::NISPlus::nis_remove_entry($me->fullPath,
    &Net::NISPlus::REM_MULTIPLE);
  if ($ret != 0)
  {
    Warning("clear error: ", niserror($ret), "\n");
    return 0;
  }
  else
  {
    return 1;
  }
}

=head2 modify

Change fields in a table entry.

$table->modify({'key1' => 'value1', 'key2' => 'value2'}, {'key3' => 'newvalue3'});

or

$table->modify("[key1=value1,key2=value2]", {'key3' => 'newvalue3'});

If you specify the table name in the indexed name form, it will be
removed and replaced with the full name determined when the table
object was created (and accessible with $table->fullName);

=cut

sub modify
{
  my($me, $search, $replace) = @_;
  my($ret);

  my($name) = $me->indexedName($search);
  ($ret) = Net::NISPlus::nis_modify_entry($name, $replace, 0);
  if ($ret != 0)
  {
    Warning("modify error: ", niserror($ret), "\n");
    return 0;
  }
  else
  {
    return 1;
  }
}

=head2 first_entry

first_entry retrieves the first entry in the table.  Data is returned
in an array.

@fields = $table->first_entry();

=cut

sub first_entry
{
  my($me) = @_;
  my($ret, $cookie, $res);

  ($ret, $cookie, $res) = Net::NISPlus::nis_first_entry($me->fullPath);
  if ($ret != 0) {
    Warning("first_entry error: ", niserror($ret), "\n");
    return ();
  } else {
    $me->{'cookie'} = $cookie;
    return @{$res};
  }
}

=head2 next_entry

next_entry successively returns the next entry in the table.
first_entry should be called before next_entry.  Data is returned in
an array.

@fields = $table->next_entry();

=cut

sub next_entry
{
  my($me) = @_;
  my($ret, $cookie, $res);

  ($ret, $cookie, $res) = Net::NISPlus::nis_next_entry($me->fullPath,
						       $me->{'cookie'});
  if ($ret != 0) {
    Warning("next_entry error: ", niserror($ret), "\n");
    return ();
  } else {
    $me->{'cookie'} = $cookie;
    return @{$res};
  }
}

sub chmod
{
}

sub chown
{
}

sub DESTROY
{
}

# takes either a string of the form [a=b,c=d] or a hash reference of the form
# { 'a'=>'b', 'c'=>'d' } and returns a canonical indexed name.
sub indexedName
{
  my($me, $arg) = @_;
  my($name);
# if the argument is a hashref, then we build the indexed name from the hash.  
  if (ref($arg) eq "hash")
  {
    $name = "[";
    foreach $key (keys %$arg)
    {
      die "$key does not exist in ".$me->fullPath."\n" unless $me->isColname($key);
      $name .= "," unless length($name) == 1;
      $name .= "$key=$arg->{$key}";
    }
    $name .= "]";
  }
  else
# if the argument is not a hashref, then it should be a string
  {
    $name = $arg;
# if the user specifies a table name, it will be deleted and replaced
# with the full path
    $name =~ s/,.*//;
  }
  $name .= ",".$me->fullPath;
}

sub fullPath
{
  my($me) = shift;

  $me->{'full_path'};
}

=head2 isColname

returns TRUE if the given argument is a valid column name for the
table

$table->isColname("name");

=cut

sub isColname
{
  my($me, $val) = @_;
  my($colnames);
  $colnames = $me->colnames;
  return exists $colnames->{$val};
}

sub niserror
{
  my($err) = shift;
  Net::NISPlus::nis_sperrno($err)." ($err)";
}

sub Warning
{
  Net::NISPlus::prwarning(@_);
}

sub Debug
{
  Net::NISPlus::prdebug(@_);
}
1;
__END__
