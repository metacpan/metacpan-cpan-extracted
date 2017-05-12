
package Tangram::Type::Dump::YAML;

=head1 NAME

Tangram::Type::Dump::YAML - serialise fields of an object via YAML to a column

=head1 SYNOPSIS

   use Tangram::Core;
   use Tangram::Type::Dump::YAML;

   $schema = Tangram::Schema->new(
      classes => { NaturalPerson => { fields => {

      yaml =>
      {
         diary => # diary is a perl hash 
         {
            col => 'diarydata',
            sql => 'TEXT', # better be large enough!  :)

            # YAML dumper control, values here are defaults
            options => {
                Indent => 2,
                UseHeader => 1,
                UseVersion => 1,
                SortKeys => 1,
                UseCode => 0,
                # ... etc, see the YAML man page for more
            },

      }

      }}});

=head1 DESCRIPTION

Tangram::Type::Dump::YAML is very much like Tangram::Type::Dump::Perl, only serialisation
is achieved via YAML and not Data::Dumper.

This is currently untested, but is known to have bugs, largely to do
with the fact that YAML can't serialise blessed references (see
L<http://rt.cpan.org/NoAuth/Bug.html?id=4784>).

=cut

use strict;
use Tangram::Type::Scalar;
use YAML qw(freeze thaw);

use vars qw(@ISA);
@ISA = qw( Tangram::Type::String );

use Set::Object qw(reftype);

$Tangram::Schema::TYPES{yaml} = Tangram::Type::Dump::YAML->new;

sub reschema {

  my ($self, $members, $class, $schema) = @_;

  if (ref($members) eq 'ARRAY') {
      # short form
      # transform into hash: { fieldname => { col => fieldname }, ... }
      $_[1] = map { $_ => { col => $schema->{normalize}->($_, 'colname') } }
	  @$members;
  }

  for my $field (keys %$members) {

      my $def = $members->{$field};
      my $refdef = reftype($def);

      unless ($refdef) {
	  # not a reference: field => field
	  $def = $members->{$field}
	      = { col => $schema->{normalize}->(($def || $field), 'colname') };
	  $refdef = reftype($def);
      }

      die ref($self).": $class\:\:$field: unexpected $refdef"
	  unless $refdef eq 'HASH';

      $def->{col} ||= $schema->{normalize}->($field, 'colname');
      $def->{sql} ||= 'VARCHAR(255)'; # not a great default, but hey, it's
                                      # portable
      $def->{options} ||= { };
      $def->{dumper} = sub {
	  freeze(shift);
      };

  }

  return keys %$members;
}

sub get_importer
{
	my ($self, $context) = @_;
        return("{ my \$x = '--- ' . ((shift \@\$row)||'~').'\n';
                \$obj->{$self->{name}} = eval { YAML::thaw(\$x) };\n"
	       .'die("YAML error; `$@` loading: |\n$x\n...\n") if $@;'
               ."Tangram::Type::Dump::unflatten(\$context->{storage}, "
               ."\$obj->{$self->{name}}) }");
  }

sub get_exporter
  {
	my ($self, $context) = @_;
	my $field = $self->{name};

	return sub {
	  my ($obj, $context) = @_;
	  Tangram::Type::Dump::flatten($context->{storage},
				 $obj->{$field});
	  my $text = $self->{dumper}->($obj->{$field});
          $text =~ s{\A--- *|\n\Z}{}g;
	  Tangram::Type::Dump::unflatten($context->{storage},
				   $obj->{$field});
	  return $text;
	};
  }

sub save {
  my ($self, $cols, $vals, $obj, $members, $storage) = @_;
  
  my $dbh = $storage->{db};
  
  foreach my $member (keys %$members) {
    my $memdef = $members->{$member};
    
    next if $memdef->{automatic};
    
    push @$cols, $memdef->{col};
    push @$vals, $dbh->quote(&{$memdef->{dumper}}($obj->{$member}));
  }
}

1;
