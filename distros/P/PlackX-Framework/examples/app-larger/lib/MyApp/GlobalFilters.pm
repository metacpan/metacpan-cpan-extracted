use v5.36;
package MyApp::GlobalFilters {
  use MyApp::Router;
  use Time::HiRes ();

  global_filter before => sub ($request, $response) {
    $request->stash->{response_start_time} = Time::HiRes::time();
    return $response->next;
  };

  global_filter after => sub ($request, $response) {
    my $start = $request->stash_param('response_start_time');
    my $end   = Time::HiRes::time();
    my $elapsed = int(10000 * ($end - $start))/100;
    my $info    = <<~HEREDOC;

      MyApp::GlobalFilters
      Debugging:
        Request  object: $request
        Response object: $response
        Start time:      $start
        End time:        $end
        Elapsed time:    $elapsed ms
      HEREDOC

    if ($response->content_type =~ m/html/) {
      $response->print("<!--$info-->");
    } elsif ($response->content_type =~ m/plain/) {
      $response->print($info);
    } else {
      warn $info;
    }
    return;
  };
}

1;
