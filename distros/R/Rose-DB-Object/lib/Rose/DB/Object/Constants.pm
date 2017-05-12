package Rose::DB::Object::Constants;

use strict;

our $VERSION = '0.791';

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = 
  qw(PRIVATE_PREFIX META_ATTR_NAME ON_SAVE_ATTR_NAME 
     LOADED_FROM_DRIVER FLAG_DB_IS_PRIVATE MODIFIED_COLUMNS 
     MODIFIED_NP_COLUMNS SET_COLUMNS SAVING_FOR_LOAD
     STATE_IN_DB STATE_LOADING STATE_SAVING STATE_CLONING
     EXCEPTION_CODE_NO_KEY);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant PRIVATE_PREFIX      => '__xrdbopriv';
use constant META_ATTR_NAME      => PRIVATE_PREFIX . '_meta';
use constant ON_SAVE_ATTR_NAME   => PRIVATE_PREFIX . '_on_save';
use constant LOADED_FROM_DRIVER  => PRIVATE_PREFIX . '_loaded_from_driver';
use constant FLAG_DB_IS_PRIVATE  => PRIVATE_PREFIX . '_db_is_private';
use constant MODIFIED_COLUMNS    => PRIVATE_PREFIX . '_modified_columns';
use constant MODIFIED_NP_COLUMNS => PRIVATE_PREFIX . '_modified_np_columns';
use constant SET_COLUMNS         => PRIVATE_PREFIX . '_set_columns';
use constant SAVING_FOR_LOAD     => PRIVATE_PREFIX . '_saving_for_load';
use constant STATE_IN_DB         => PRIVATE_PREFIX . '_in_db';
use constant STATE_LOADING       => PRIVATE_PREFIX . '_loading';
use constant STATE_SAVING        => PRIVATE_PREFIX . '_saving';
use constant STATE_CLONING       => STATE_SAVING;

use constant EXCEPTION_CODE_NO_KEY => 5; # arbitrary

1;
