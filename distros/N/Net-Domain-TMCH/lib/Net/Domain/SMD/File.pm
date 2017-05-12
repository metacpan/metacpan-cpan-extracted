# Copyrights 2013-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Net::Domain::SMD::File;
use vars '$VERSION';
$VERSION = '0.18';

use parent 'Net::Domain::SMD';

use Log::Report   'net-domain-smd';

use MIME::Base64       qw/decode_base64/;
use XML::LibXML        ();
use POSIX              qw/mktime tzset/;
use XML::Compile::Util qw/type_of_node/;
use List::Util         qw/first/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    # Clean object construction is needed when we are going to write
    # SMD files... but we won't for now.
    $self->{NDSF_fn}     = $args->{filename} or panic;
    $self->{NDSF_marks}  = $args->{marks};
    $self->{NDSF_labels} = $args->{labels};
    $self;
}


sub fromFile($%)
{   my ($class, $fn, %args) = @_;

    my $schemas = $args{schemas} or panic;

    open my($fh), '<:raw', $fn
        or fault __x"cannot read from smd file {fn}", fn => $fn;

    my $xml;
    my ($marks, $labels);
  LINE:
    while(<$fh>)
    {   next LINE if m/^#|^\s*$/;   # not yet permitted in those files
        if( m/^-{3,}BEGIN .* SMD/)
        {   my @smd;
            while(<$fh>)
            {   last if m/^-{3,}END .* SMD/;
                push @smd, $_;
            }
            $xml = \decode_base64(join '', @smd);
            next LINE;
        }

        # Only few of the fields are of interest: often better inside XML
        my ($label, $value) = split /\:\s+/;
        defined $value && length $value or next;
        $label = lc $label;
        $value =~ s/\s*$//s;
        if($label eq 'u-labels')
        {   $labels = [split /\s*\,\s*/, $value];
        }
        elsif($label eq 'marks')  # trademark names?  Comma list?
        {   $marks  =  [split /\s*\,\s*/, $value];
        }

    }

    $xml or error __x"there is not SMD information in {fn}", fn => $fn;

    my $root = $schemas->dataToXML($xml);
    $class->fromNode($root, filename => $fn, marks => $marks
      , labels => $labels, %args);
}
    
#----------------

sub filename()  {shift->{NDSF_fn}}
sub labels()    { @{shift->{NDSF_labels} || []} }
sub marks()     { @{shift->{NDSF_marks}  || []} }

1;
