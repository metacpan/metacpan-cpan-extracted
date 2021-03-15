use strict;
use warnings;

package Smartcat::App::Constants;
use base 'Exporter';

our @EXPORT_OK = qw(
  COMPLETE
  EXPORT_ZIP_FILES_COUNT
  MAX_ITERATION_WAIT_TIMEOUT
  ITERATION_WAIT_TIMEOUT
  DOCUMENT_DISASSEMBLING_SUCCESS_STATUS
  PATH_SEPARATOR
);

use constant COMPLETE                              => 'completed';
use constant EXPORT_ZIP_FILES_COUNT                => 10;
use constant MAX_ITERATION_WAIT_TIMEOUT            => 300;
use constant ITERATION_WAIT_TIMEOUT                => 1;
use constant DOCUMENT_DISASSEMBLING_SUCCESS_STATUS => 'success';
use constant PATH_SEPARATOR => '/';

1;