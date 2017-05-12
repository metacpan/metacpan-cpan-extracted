=pod Memo

tieインターフェイスはうまく動かせない。

	$rubyobject->{$key} = $rubyval;

この代入コードは何故か$$rubyvalのREFCNTを増加させてしまうようだ。

また，現在はインスタンス変数にアクセスするためにハッシュインターフェイスを用いているので，そのままではハッシュインターフェイスは使えない。

=cut


{
	our $NEGATIVE_INDICES = 1; # for tied array

	no strict 'refs';

	*FETCHSIZE = \&size;
	*STORESIZE = \&resize;
	*FETCH     = \&{'Ruby::Object::[]'};
	*STORE     = \&{'Ruby::Object::[]='};

	*EXISTS    = \&has_key;
	*DELETE    = \&delete;

	*CLEAR     = \&clear;
	*PUSH      = \&push;
	*POP       = \&pop;
	*SHIFT     = \&shift;
	*UNSHIFT   = \&unshift;
	*SPLICE    = \&splice;

	sub EXTEND{}
}
	