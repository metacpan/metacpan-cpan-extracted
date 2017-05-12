package SQL::Translator::Producer::DBIx::Class::File::Simple;

=head1 NAME

SQL::Translator::Producer::DBIx::Class::File::Simple - DBIx::Class file producer

=head1 SYNOPSIS

  use SQL::Translator;

  my $t = SQL::Translator->new( parser => '...', 
                                producer => 'DBIx::Class::File::Simple',
                                no_comments         => 0 );
  print $translator->translate( $file );

Or use it as command:
    
  sqlt -f DBI --dsn $dsn --db-user $user --db-password $pass -t DBIx::Class::File::Simple --no-comments --prefix=$prefix > $tofile

=head1 DESCRIPTION

Creates a DBIx::Class::Schema for use with DBIx::Class

IF no_comments == 0,it won't print detail for columns,whereas if no_comments == 1 ,it will.
For most cases,we need not those detail information.

=cut

use strict;
use vars qw[ $VERSION $DEBUG $WARN ];
$VERSION = '0.1';
$DEBUG   = 0 unless defined $DEBUG;

use SQL::Translator::Schema::Constants;
use SQL::Translator::Utils qw(header_comment);

## Skip all column type translation, as we want to use whatever the parser got.

sub produce
{
    my ($translator) = @_;
    $DEBUG             = $translator->debug;
    $WARN              = $translator->show_warnings;
    my $no_comments    = $translator->no_comments;
    my $add_drop_table = $translator->add_drop_table;
    my $schema         = $translator->schema;
    my $output         = '';

    # Steal the XML producers "prefix" arg for our namespace?
    my $dbixschema     = $translator->producer_args()->{prefix} || 
        $schema->name || 'My::Schema';

    my %tt_vars = ();
    $tt_vars{dbixschema} = $dbixschema;

    my $schemaoutput .= << "DATA";

package ${dbixschema};
use base 'DBIx::Class::Schema';
use strict;
use warnings;
DATA

    my %tableoutput = ();
    my %tableextras = ();
    foreach my $table ($schema->get_tables)
    {
        my $tname = $table->name;
        my $uc_tname = my_uc($tname);
        my $output .= qq{

package ${dbixschema}::${uc_tname};
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('${tname}');

};

        my @fields = map 
        { { $_->name  => {
            name              => $_->name,
            is_auto_increment => $_->is_auto_increment,
            is_foreign_key    => $_->is_foreign_key,
            is_nullable       => $_->is_nullable,
            default_value     => $_->default_value,
            data_type         => $_->data_type,
            size              => $_->size,
        } }
         } ($table->get_fields);
        
        if($no_comments){
            $output .= "\n__PACKAGE__->add_columns(qw/";
            foreach my $f (@fields)
            {
                local $Data::Dumper::Terse = 1;
                $output .= (keys %$f)[0] . " ";
            }
            $output .= "/);\n";
        }else{
            $output .= "\n__PACKAGE__->add_columns(";
            foreach my $f (@fields)
            {
                local $Data::Dumper::Terse = 1;
                $output .= "\n    '" . (keys %$f)[0] . "' => " ;
                my $colinfo =
                    Data::Dumper->Dump([values %$f],
                                       [''] # keys   %$f]
                                       );
                chomp($colinfo);
                $output .= $colinfo . ",";
            }
            $output .= "\n);\n";
        }

        my $pk = $table->primary_key;
        if($pk)
        {
            my @pk = map { $_->name } ($pk->fields);
            $output .= "__PACKAGE__->set_primary_key(";
            $output .= "'" . join("', '", @pk) . "');\n";
        }

        foreach my $cont ($table->get_constraints)
        {
            if($cont->type =~ /foreign key/i)
            {
                $tableextras{$table->name} .= "\n__PACKAGE__->belongs_to('" . 
                    $cont->fields->[0]->name . "', '" .
                    "${dbixschema}::" . $cont->reference_table . "');\n";
                
                my $other = "\n__PACKAGE__->has_many('" .
                    "get_" . $table->name. "', '" .
                    "${dbixschema}::" . $table->name. "', '" .
                    $cont->fields->[0]->name . "');";
                $tableextras{$cont->reference_table} .= $other;
            }
        }

        $tableoutput{$table->name} .= $output;
    }

    foreach my $to (keys %tableoutput)
    {
        $output .= $tableoutput{$to};
        $schemaoutput .= "\n__PACKAGE__->register_class('${to}', '${dbixschema}::${to}');\n"; 
    }

    foreach my $te (keys %tableextras)
    {
        $output .= "\npackage ${dbixschema}::$te;\n";
        $output .= $tableextras{$te} . "\n";
    }

    return "${output}\n\n${schemaoutput}\n1;\n";
}

sub my_uc {
    my $table = shift;
    my @pieces = split '_', $table;
    @pieces = map { ucfirst($_) } @pieces;
    $table = join( '', @pieces );
}

1;