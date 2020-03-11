package Mojolicious::Plugin::Minion::Overview::Backend::mysql;
use Mojo::Base 'Mojolicious::Plugin::Minion::Overview::Backend';

use Mojo::JSON qw(decode_json);


=head2 failed_jobs

Search failed jobs

=cut

sub failed_jobs {
    return shift->where('state', 'failed')
        ->jobs();
}

=head2 job_runtime_metrics

Job runtime metrics

=cut

sub job_runtime_metrics {
    my ($self, $job) = @_;

    my $start = $self->start;

    my $sql = <<SQL;
SELECT
    `minion_jobs`.`started` AS `x`,
    TIME_TO_SEC(TIMEDIFF(COALESCE(`minion_jobs`.`finished`, NOW()), `minion_jobs`.`started`)) AS `y`,
    `minion_jobs`.`state`
FROM `minion_jobs`
WHERE
    `minion_jobs`.`task` = ?
    AND `minion_jobs`.`created` >= $start
ORDER BY `minion_jobs`.`created`
LIMIT 1000
SQL
    
    my $collection = $self->db->query($sql, $job)->hashes;

    return $collection;
}

=head2 job_throughput_metrics

Job throughput metrics

=cut

sub job_throughput_metrics {
    my ($self, $job) = @_;

    my $start = $self->start;

    my $sql = <<SQL;
SELECT
    DATE_FORMAT(`minion_jobs`.`started`, "%Y-%m-%d %H:00:00") AS `x`,
    COUNT(*) AS `y`,
    `minion_jobs`.`state`
FROM `minion_jobs`
WHERE
    `minion_jobs`.`task` = ?
    AND `minion_jobs`.`created` >= $start
GROUP BY `x`, `minion_jobs`.`state`
ORDER BY `x` ASC
SQL
    
    my $collection = $self->db->query($sql, $job)->hashes;

    return $collection;
}

=head2 jobs

Search jobs

=cut

sub jobs {
    my $self = shift;

    my @where = ('`minion_jobs`.`created` >= ' . $self->start);
    my @params;

    # Search by term
    if (my $term = $self->query->{ term }) {
        push(@where, 'CONCAT(`minion_jobs`.`task`, CAST(`minion_jobs`.`notes` AS CHAR)) LIKE ?');
        push(@params, '%' . $term . '%');
    }

    # Search where fields
    for my $field (keys(%{ $self->query->{ where } })) {
        push(@where, "`$field` = ?");
        push(@params, $self->query->{ where }->{ $field });
    }

    # Search tags
    for my $tag (@{ $self->query->{ tags } }) {
        push(@where, '(`minion_jobs`.`notes` LIKE ? OR `minion_jobs`.`task` = ?)');
        push(@params, '%"tags":[%' . $tag . '%]%', $tag);
    }

    my $where_clause = join("\n    and ", @where);

    my $sql_count = <<SQL;
SELECT
    count(*) AS `total`
FROM `minion_jobs`
LEFT JOIN `minion_jobs_depends` ON `minion_jobs_depends`.`child_id` = `minion_jobs`.`id`
WHERE
    $where_clause
SQL

    my $total = $self->db->query($sql_count, @params)->hash->{ total };

    my $sql = <<SQL;
SELECT
    `minion_jobs`.*,
    `minion_jobs_depends`.`parent_id`,
    TIME_TO_SEC(TIMEDIFF(IF(`minion_jobs`.`finished` = '0000-00-00 00:00:00', NOW(), `minion_jobs`.`finished`), IF(`minion_jobs`.`started` = '0000-00-00 00:00:00', NOW(), `minion_jobs`.`started`))) AS `runtime`
FROM `minion_jobs`
LEFT JOIN `minion_jobs_depends` ON `minion_jobs_depends`.`child_id` = `minion_jobs`.`id`
WHERE
    $where_clause
ORDER BY `minion_jobs`.`created` DESC
LIMIT ?
OFFSET ?
SQL

    my $offset = ($self->query->{ page } - 1) * $self->query->{ limit };

    push(@params, $self->query->{ limit }, $offset);
    
    my $collection = $self->db->query($sql, @params)->hashes;
    my $count = scalar(@$collection);

    $collection->each(sub {
        my $object = shift;

        $object->{ tags } = eval { decode_json($object->{ notes })->{ tags } || [$object->{ task }] };
    });

    my $response = {
        results => $collection,
        query   => {
            %{ $self->query },
            total       => $total,
            prev_page   => {
                term    => $self->query->{ term },
                tags    => $self->query->{ tags },
                page    => ($self->query->{ page } - 1) || 0,
                %{ $self->query->{ where } }
            },
            next_page   => {
                term    => $self->query->{ term },
                tags    => $self->query->{ tags },
                page    => $count < $self->query->{ limit } ? $self->query->{ page } : $self->query->{ page } + 1,
                %{ $self->query->{ where } }
            }
        },
    };

    # Clear query
    $self->clear_query;

    return $response;
}

=head2 overview

Dashboard overview

=cut

sub overview {
    my $self = shift;

    my $start = $self->start;

    my $stats_sql = <<SQL;
SELECT
    COALESCE(SUM(IF(`minion_jobs`.`state` = 'finished', 1, 0)), 0) AS `finished`,
    COALESCE(SUM(IF(`minion_jobs`.`state` = 'failed', 1, 0)), 0) AS `failed`,
    COALESCE(SUM(IF(`minion_jobs`.`state` = 'active', 1, 0)), 0) AS `active`,
    COALESCE(SUM(IF(`minion_jobs`.`state` = 'inactive', 1, 0)), 0) AS `inactive`
FROM `minion_jobs`
WHERE
    `minion_jobs`.`created` >= $start
SQL
    
    my $jobs = $self->db->query($stats_sql)->hash;

    my $workers_sql = <<SQL;
SELECT
    COUNT(*) AS `workers`
FROM `minion_workers`
SQL
    
    my $workers = $self->db->query($workers_sql)->hash->{ workers };

    return [
        {
            title   => 'Finished jobs',
            count   => $jobs->{ finished },
        },
        {
            title   => 'Failed jobs',
            count   => $jobs->{ failed },
        },
        {
            title   => 'Active jobs',
            count   => $jobs->{ active },
        },
        {
            title   => 'Inactive jobs',
            count   => $jobs->{ inactive },
        },
        {
            title   => 'Active workers',
            count   => $workers,
        },
    ];
}

=head2 unique_jobs

Search the list of unique jobs

=cut

sub unique_jobs {
    my $self = shift;

    my @where = ('`minion_jobs`.`created` >= ' . $self->start, "`minion_jobs`.`state` IN ('finished', 'failed')");
    my @params;

    # Search by term
    if (my $term = $self->query->{ term }) {
        push(@where, 'CONCAT(`minion_jobs`.`task`, CAST(`minion_jobs`.`notes` AS CHAR)) LIKE ?');
        push(@params, '%' . $term . '%');
    }

    my $where_clause = join("\n    and ", @where);

    my $sql_count = <<SQL;
SELECT
    COUNT(DISTINCT(`minion_jobs`.`task`)) AS `total`
FROM `minion_jobs`
WHERE
    $where_clause
SQL

    my $total = $self->db->query($sql_count)->hash->{ total };

    my $sql = <<SQL;
SELECT
    `task`,
    CAST(COALESCE(`finished_in` / `finished`, 0) AS DECIMAL(10,2)) AS `finished`,
    CAST(COALESCE(`failed_in` / `failed`, 0) AS DECIMAL(10,2)) AS `failed`
FROM (
    SELECT
        `task`,
        SUM(IF(`minion_jobs`.`state` = 'finished', TIME_TO_SEC(TIMEDIFF(`minion_jobs`.`finished`, `minion_jobs`.`started`)), 0)) AS `finished_in`,
        SUM(IF(`minion_jobs`.`state` = 'finished', 1, 0)) AS `finished`,
        SUM(IF(`minion_jobs`.`state` = 'failed', TIME_TO_SEC(TIMEDIFF(`minion_jobs`.`finished`, `minion_jobs`.`started`)), 0)) AS `failed_in`,
        SUM(IF(`minion_jobs`.`state` = 'failed', 1, 0)) AS `failed`

    FROM `minion_jobs`
    WHERE
        $where_clause
    GROUP BY `minion_jobs`.`task`
    LIMIT ?
    OFFSET ?
) AS `metrics`
ORDER BY COALESCE(`finished_in` / `finished`, 0) DESC
SQL

    my $offset = ($self->query->{ page } - 1) * $self->query->{ limit };
    
    push(@params, $self->query->{ limit }, $offset);
    
    my $collection = $self->db->query($sql, @params)->hashes;
    my $count = scalar(@$collection);

    my $response = {
        results => $collection,
        query   => {
            %{ $self->query },
            total       => $total,

            prev_page   => {
                term    => $self->query->{ term },
                tags    => $self->query->{ tags },
                page    => ($self->query->{ page } - 1) || 0,
                %{ $self->query->{ where } }
            },
            next_page   => {
                term    => $self->query->{ term },
                tags    => $self->query->{ tags },
                page    => $count < $self->query->{ limit } ? $self->query->{ page } : $self->query->{ page } + 1,
                %{ $self->query->{ where } }
            }
        },
    };
    
    # Clear query
    $self->clear_query;

    return $response;
}

=head2 worker

Find a worker by id

=cut

sub worker {
    my ($self, $id) = @_;


    my $sql = <<SQL;
SELECT
    `minion_workers`.*,
    CAST(AVG(TIME_TO_SEC(TIMEDIFF(`minion_jobs`.`started`, `minion_jobs`.`created`))) AS DECIMAL(10, 2)) AS `wait`
FROM `minion_workers`
INNER JOIN `minion_jobs` on `minion_jobs`.`worker` = `minion_workers`.`id`
WHERE
    `minion_workers`.`id` = ?
SQL

    my $worker = $self->db->query($sql, $id)->hash;

    return $worker;
}

=head2 worker_waittime_metrics

Worker waittime metrics

=cut

sub worker_waittime_metrics {
    my ($self, $worker_id) = @_;

    my $start = $self->start;

    my $sql = <<SQL;
SELECT
    `minion_jobs`.`created` AS `x`,
    TIME_TO_SEC(TIMEDIFF(`minion_jobs`.`started`, `minion_jobs`.`created`)) AS `y`,
    `minion_jobs`.`state`
FROM `minion_jobs`
INNER JOIN `minion_workers` on `minion_workers`.`id` = `minion_jobs`.`worker`
WHERE
    `minion_workers`.`id` = ?
    AND `minion_jobs`.`created` >= $start
ORDER BY `minion_jobs`.`created`
LIMIT 1000
SQL
    
    my $collection = $self->db->query($sql, $worker_id)->hashes;

    return $collection;
}

=head2 worker_throughput_metrics

Worker throughput metrics

=cut

sub worker_throughput_metrics {
    my ($self, $worker_id) = @_;

    my $start = $self->start;

    my $sql = <<SQL;
SELECT
    DATE_FORMAT(`minion_jobs`.`started`, "%Y-%m-%d %H:00:00") AS `x`,
    COUNT(*) AS `y`,
    `minion_jobs`.`state`
FROM `minion_jobs`
INNER JOIN `minion_workers` on `minion_workers`.`id` = `minion_jobs`.`worker`
WHERE
    `minion_workers`.`id` = ?
    AND `minion_jobs`.`created` >= $start
GROUP BY `x`, `state`
ORDER BY `x` ASC
SQL
    
    my $collection = $self->db->query($sql, $worker_id)->hashes;

    return $collection;
}

=head2 workers

Get workers information

=cut

sub workers {
    my $self = shift;

    my $sql = <<SQL;
SELECT
    `minion_workers`.*,
    CAST(AVG(TIME_TO_SEC(TIMEDIFF(`minion_jobs`.`started`, `minion_jobs`.`created`))) AS DECIMAL(10, 2)) AS `wait`
FROM `minion_workers`
INNER JOIN `minion_jobs` on `minion_jobs`.`worker` = `minion_workers`.`id`
GROUP BY `minion_workers`.`id`
SQL

    my $stats_sql = <<SQL;
SELECT
    COUNT(*) AS `performed`,
    COALESCE(SUM(IF(`minion_jobs`.`state` = 'active', 1, 0)), 0) AS `active`,
    COALESCE(SUM(IF(`minion_jobs`.`state` = 'finished', 1, 0)), 0) AS `finished`,
    COALESCE(SUM(IF(`minion_jobs`.`state` = 'failed', 1, 0)), 0) AS `failed`
FROM `minion_jobs`
INNER JOIN `minion_workers` on `minion_workers`.`id` = `minion_jobs`.`worker`
WHERE
    `minion_workers`.`id` = ?
SQL
    
    my $collection = $self->db->query($sql)->hashes;

    $collection->each(sub {
        my $object = shift;

        $object->{ status } = eval { decode_json($object->{ status }) };
        $object->{ jobs_stats } = $self->db->query($stats_sql, $object->{ id })->hash;
    });

    return $collection;
}

1;
