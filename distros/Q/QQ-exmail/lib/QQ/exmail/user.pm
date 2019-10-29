package QQ::exmail::user;

=encoding utf8

=head1 Name
QQ::exmail::user

=head1 DESCRIPTION
通讯录管理->管理成员
=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.06';
our @EXPORT = qw/ create update delete get simplelist list batchcheck /;

=head2 create
create(access_token, hash);
创建成员
L<https://exmail.qq.com/qy_mng_logic/doc#10014>
=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/user/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update
update(access_token, hash);
更新成员
L<https://exmail.qq.com/qy_mng_logic/doc#10015>
=cut

sub update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/user/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete
delete(access_token, userid);
删除成员
L<https://exmail.qq.com/qy_mng_logic/doc#10016>
=cut

sub delete {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/delete?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get
get(access_token, userid);
获取成员
L<https://exmail.qq.com/qy_mng_logic/doc#10017>
=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/get?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 simplelist
simplelist(access_token, department_id, fetch_child);
获取部门成员
L<https://exmail.qq.com/qy_mng_logic/doc#10018>
=cut

sub simplelist {
    if ( @_ && $_[0] && $_[1] && $_[2] ) {
        my $access_token = $_[0];
        my $department_id = $_[1];
        my $fetch_child = $_[2]
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/simplelist?access_token=$access_token&department_id=$department_id&fetch_child=$fetch_child");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list
list(access_token, department_id, fetch_child);
获取部门成员（详情）
L<https://exmail.qq.com/qy_mng_logic/doc#10019>
=cut

sub list {
    if ( @_ && $_[0] && $_[1] && $_[2] ) {
        my $access_token = $_[0];
        my $department_id = $_[1];
        my $fetch_child = $_[2]
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/list?access_token=$access_token&department_id=$department_id&fetch_child=$fetch_child");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 batchcheck
batchcheck(access_token, hash);
批量检查账号
L<https://exmail.qq.com/qy_mng_logic/doc#10020>
=cut

sub batchcheck {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/user/batchcheck?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
