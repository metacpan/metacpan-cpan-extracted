


create table download_status (
	status_id integer primary key,

	name varchar(256) not null,
    is_current int not null
)
/

insert into download_status (status_id, name, is_current) values(100, 'queued', 1)
/
insert into download_status (status_id, name, is_current) values(200, 'downloading', 1)
/
insert into download_status (status_id, name, is_current) values(7200, 'downloaded: failed', 1)
/
insert into download_status (status_id, name, is_current) values(9200, 'downloaded: ok', 0)
/




create table download (
	download_id integer primary key,

	url varchar(512) not null,
	url_referer varchar(512) null,                    --If any, the HTTP_REFERER to use
	domain varchar(256) not null,

    bytes_content int default 0,                      --The Content-Length
    bytes_downloaded int default 0,                   --The total bytes downloaded so far

	dir_download varchar(256) not null default '.',   --Where to download to. Will be created.
    file_download varchar(256) not null,              --Which file name to download to in the dir.

    download_status_id int not null default 100 references download_status
)
/




--END
