package Mojolicious::Plugin::Minion::Overview::Backend::mysql;
use Mojo::Base 'Mojolicious::Plugin::Minion::Overview::Backend';

use Mojo::JSON qw(decode_json);

sub children {

}

sub dashboard {
    my $self = shift;

my $sql = <<SQL;
SELECT
    SUM(IF(state = 'finished', 1, 0)) AS `finished`,
    SUM(IF(state = 'failed', 1, 0)) AS `failed`,
    SUM(IF(state = 'inactive', 1, 0)) AS `inactive`
FROM `minion_jobs`
WHERE
    `created` >= DATE_ADD(NOW(), INTERVAL -7 DAY)
    AND `state` IN ('finished', 'failed')
SQL
    
    my $finished = $self->db->query($sql)->hash->{ finished };
    my $failed = $self->db->query($sql)->hash->{ failed };
    my $inactive = $self->db->query($sql)->hash->{ inactive };

$sql = <<SQL;
SELECT
    COUNT(*) AS `workers`
FROM `minion_workers`
SQL

    my $workers = $self->db->query($sql)->hash->{ workers };

    return [
        {
            title   => 'Finished jobs past 7 days',
            count   => $finished,
        },
        {
            title   => 'Failed jobs past 7 days',
            count   => $failed,
        },
        {
            title   => 'Inactive jobs past 7 days',
            count   => $inactive,
        },
        {
            title   => 'Active workers',
            count   => $workers,
        },
    ];
}

sub failed_jobs {
    return shift->where('state', 'failed')
        ->jobs();
}

sub job_runtime_metrics {
    my ($self, $job) = @_;

    my $sql = <<SQL;
SELECT
    `started` AS `x`,
    TIME_TO_SEC(TIMEDIFF(COALESCE(`finished`, NOW()), `started`)) AS `y`,
    `state`
FROM `minion_jobs`
WHERE
    `task` = ?
    AND `created` >= DATE_ADD(NOW(), INTERVAL -7 DAY)
ORDER BY `minion_jobs`.`created`
LIMIT 1000
SQL
    
    my $collection = $self->db->query($sql, $job)->hashes;

    return $collection;
}

sub job_throughput_metrics {
    my ($self, $job) = @_;

    my $sql = <<SQL;
SELECT
    DATE_FORMAT(`started`, "%Y-%m-%d %H:00:00") AS `x`,
    COUNT(*) AS `y`,
    `state`
FROM `minion_jobs`
WHERE
    `task` = ?
    AND `created` >= DATE_ADD(NOW(), INTERVAL -7 DAY)
GROUP BY `x`, `state`
ORDER BY `x` ASC
LIMIT 1000
SQL
    
    my $collection = $self->db->query($sql, $job)->hashes;

    return $collection;
}

sub jobs {
    my $self = shift;

    my @where = ('`created` >= DATE_ADD(NOW(), INTERVAL -7 DAY)');
    my @params;

    # Search by term
    if (my $term = $self->query->{ term }) {
        push(@where, 'CONCAT(`task`, CAST(`notes` AS CHAR)) LIKE ?');
        push(@params, '%' . $term . '%');
    }

    # Search where fields
    for my $field (keys(%{ $self->query->{ where } })) {
        push(@where, "`$field` = ?");
        push(@params, $self->query->{ where }->{ $field });
    }

    # Search tags
    for my $tag (@{ $self->query->{ tags } }) {
        push(@where, '(`notes` LIKE ? OR `task` = ?)');
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
    TIME_TO_SEC(TIMEDIFF(IF(`finished` = '0000-00-00 00:00:00', NOW(), `finished`), IF(`started` = '0000-00-00 00:00:00', NOW(), `started`))) AS `runtime`
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

sub unique_jobs {
    my $self = shift;

    my @where = ("`state` IN ('finished', 'failed')");
    my @params;

    # Search by term
    if (my $term = $self->query->{ term }) {
        push(@where, 'CONCAT(`task`, CAST(`notes` AS CHAR)) LIKE ?');
        push(@params, '%' . $term . '%');
    }

    my $where_clause = join("\n    and ", @where);

    my $sql_count = <<SQL;
SELECT
    COUNT(DISTINCT(`task`)) AS `total`
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
        SUM(IF(`state` = 'finished', TIME_TO_SEC(TIMEDIFF(`finished`, `started`)), 0)) AS `finished_in`,
        SUM(IF(`state` = 'finished', 1, 0)) AS `finished`,
        SUM(IF(`state` = 'failed', TIME_TO_SEC(TIMEDIFF(`finished`, `started`)), 0)) AS `failed_in`,
        SUM(IF(`state` = 'failed', 1, 0)) AS `failed`

    FROM `minion_jobs`
    WHERE
        $where_clause
    GROUP BY `task`
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

1;
