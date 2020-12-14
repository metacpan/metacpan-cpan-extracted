use 5.14.0; # for the /r modifier in regex substitution
use utf8;
use strict;
use warnings;

use lib "../../MsOffice-Word-Surgeon/lib";
use lib "../lib";


use MsOffice::Word::Template;
use Module::Load;

# path to the template file
my $template_file = "describe_moose_class.tmpl.docx";

# Moose class to be described : first arg on the command line
my $class = shift // "MsOffice::Word::Template";

# load that class and get its metaclass;
load $class;
my $metaclass = $class->meta;

# open the template and generate the class description
my $template = MsOffice::Word::Template->new($template_file);
my $new_doc  = $template->process({meta => $metaclass});
my $filename = ($class =~ s/::/_/gr) . "_description.docx";
$new_doc->save_as($filename);
warn "generated $filename\n";



