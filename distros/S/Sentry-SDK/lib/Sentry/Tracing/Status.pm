package Sentry::Tracing::Status;
use Mojo::Base -base, -signatures;

use experimental qw(switch);
use HTTP::Status qw(:constants);

# The operation completed successfully.
sub Ok {'ok'}

# Deadline expired before operation could complete.
sub DeadlineExceeded {'deadline_exceeded'}

# 401 Unauthorized (actually does mean unauthenticated according to RFC 7235)
sub Unauthenticated {'unauthenticated'}

# 403 Forbidden
sub PermissionDenied {'permission_denied'}

# 404 Not Found. Some requested entity (file or directory) was not found.
sub NotFound {'not_found'}

# 429 Too Many Requests
sub ResourceExhausted {'resource_exhausted'}

# Client specified an invalid argument. 4xx.
sub InvalidArgument {'invalid_argument'}

# 501 Not Implemented
sub Unimplemented {'unimplemented'}

# 503 Service Unavailable
sub Unavailable {'unavailable'}

# Other/generic 5xx.
sub InternalError {'internal_error'}

# Unknown. Any non-standard HTTP status code.
sub UnknownError {'unknown_error'}

# The operation was cancelled (typically by the user).
sub Cancelled {'cancelled'}

# Already exists (409)
sub AlreadyExists {'already_exists'}

# Operation was rejected because the system is not in a state required for the operation's
sub FailedPrecondition {'failed_precondition'}

# The operation was aborted, typically due to a concurrency issue.
sub Aborted {'aborted'}

# Operation was attempted past the valid range.
sub OutOfRange {'out_of_range'}

# Unrecoverable data loss or corruption
sub DataLoss {'data_loss'}

sub from_http_code ($package, $code) {
  return Sentry::Tracing::Status->Ok if $code < HTTP_BAD_REQUEST;

  if ($code >= HTTP_BAD_REQUEST && $code < HTTP_INTERNAL_SERVER_ERROR) {
    given ($code) {
      when (HTTP_UNAUTHORIZED)        { return Unauthenticated() }
      when (HTTP_FORBIDDEN)           { return PermissionDenied() }
      when (HTTP_NOT_FOUND)           { return NotFound() }
      when (HTTP_CONFLICT)            { return AlreadyExists() }
      when (HTTP_PRECONDITION_FAILED) { return FailedPrecondition() }
      when (HTTP_TOO_MANY_REQUESTS)   { return ResourceExhausted() }
      default                         { return InvalidArgument() }
    }
  }

  if ($code >= HTTP_INTERNAL_SERVER_ERROR) {
    given ($code) {
      when (HTTP_NOT_IMPLEMENTED)     { return Unimplemented() }
      when (HTTP_SERVICE_UNAVAILABLE) { return Unavailable() }
      when (HTTP_GATEWAY_TIMEOUT)     { return DeadlineExceeded() }
      default                         { return InternalError() }
    }
  }
}

1;
