{
	package Hospital2;
	
	use base 'Terse';

	sub auth {
		return 1;
	}

	sub test {
		$_[1]->response->okay = 'abc';
	}

	sub unauth {
		$_[1]->response->authenticated = \0;
	}
	
	sub _logError {
		my ($self, $message) = @_;
		$message->{test} = 'okay';
		return $message;
	}

	sub _logInfo {
		my ($self, $message) = @_;
		$message->{other} = 'okay';
		return $message;
	}

	1;
}
