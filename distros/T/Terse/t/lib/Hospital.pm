{
	package Hospital;
	
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

	1;
}


