use strict;
use warnings;

package Smartcat::App::Constants;
use base 'Exporter';

our @EXPORT_OK = qw(
  COMPLETE
  EXPORT_ZIP_FILES_COUNT
  TOTAL_ITERATION_COUNT
  ITERATION_WAIT_TIMEOUT
  DOCUMENT_DISASSEMBLING_SUCCESS_STATUS
);

use constant COMPLETE                              => 'completed';
use constant EXPORT_ZIP_FILES_COUNT                => 10;
use constant TOTAL_ITERATION_COUNT                 => 10;
use constant ITERATION_WAIT_TIMEOUT                => 1;
use constant DOCUMENT_DISASSEMBLING_SUCCESS_STATUS => 'success';

1;
