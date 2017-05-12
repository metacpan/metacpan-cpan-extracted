package Pointer::sv;
use Pointer -Base;
use Config;

const sizeof => $Config{intsize} + 8;
const type => 'sv';
const pack_template => 'i!i!i!';

sub sv_any {
    ($self->get)[0];
}

sub sv_refcnt {
    ($self->get)[1];
}

sub sv_flags {
    ($self->get)[2];
}

our @EXPORT = qw(
    SVs_PADBUSY SVs_PADTMP SVs_PADMY   
    SVs_TEMP SVs_OBJECT  
    SVs_GMG SVs_SMG SVs_RMG
    SVf_IOK SVf_NOK SVf_POK SVf_ROK
    SVf_FAKE SVf_OOK SVf_BREAK SVf_READONLY
    SVp_IOK SVp_NOK SVp_POK
    SVp_SCREAM SVf_UTF8 SVf_AMAGIC
);

use constant SVs_PADBUSY  => 0x00000100;
use constant SVs_PADTMP   => 0x00000200;
use constant SVs_PADMY    => 0x00000400;
use constant SVs_TEMP     => 0x00000800;
use constant SVs_OBJECT   => 0x00001000;
use constant SVs_GMG      => 0x00002000;
use constant SVs_SMG      => 0x00004000;
use constant SVs_RMG      => 0x00008000;
use constant SVf_IOK      => 0x00010000;
use constant SVf_NOK      => 0x00020000;
use constant SVf_POK      => 0x00040000;
use constant SVf_ROK      => 0x00080000;
use constant SVf_FAKE     => 0x00100000;
use constant SVf_OOK      => 0x00200000;
use constant SVf_BREAK    => 0x00400000;
use constant SVf_READONLY => 0x00800000;
use constant SVp_IOK      => 0x01000000;
use constant SVp_NOK      => 0x02000000;
use constant SVp_POK      => 0x04000000;
use constant SVp_SCREAM   => 0x08000000;
use constant SVf_UTF8     => 0x20000000;
use constant SVf_AMAGIC   => 0x10000000;
