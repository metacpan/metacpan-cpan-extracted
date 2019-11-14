#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

plan 'tests' => 12;

my $explain = Pg::Explain->new(
    'source' => q{
GroupAggregate  (cost=522663.12..522663.20 rows=1 width=2301) (actual time=2128381.203..2128625.705 rows=217674 loops=1)
  Output: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.commodity, (concat(m.cnpj_clien (...)
  Group Key: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.commodity, (concat(m.cnpj_cl (...)
  Buffers: shared hit=855575640
  CTE vendedor_loja
    ->  Merge Full Join  (cost=135165.41..147750.26 rows=436160 width=1128) (actual time=5821.524..6640.486 rows=572488 loops=1)
          Output: COALESCE(v1.mes, v1_1.mes), COALESCE(v1.ae, v1_1.ae), COALESCE(v1.regiao, v1_1.regiao), COALESCE(v1.cidade, v1_1.cidade), COALESCE(v1.uf, v1_1.uf), COALESCE(v1.cnpj_cliente, v1_1.cnpj_cliente), v1.nome_rca, v1.nome_supervisor, v1_1.nome_r (...)
          Merge Cond: (((v1.mes)::text = (v1_1.mes)::text) AND ((v1.ae)::text = (v1_1.ae)::text) AND ((v1.regiao)::text = (v1_1.regiao)::text) AND ((v1.cidade)::text = (v1_1.cidade)::text) AND ((v1.cnpj_cliente)::text = (v1_1.cnpj_cliente)::text))
          Buffers: shared hit=35832
          ->  Sort  (cost=65905.90..66912.97 rows=402825 width=94) (actual time=2697.364..2764.972 rows=405405 loops=1)
                Output: v1.mes, v1.ae, v1.regiao, v1.cidade, v1.uf, v1.cnpj_cliente, v1.nome_rca, v1.nome_supervisor
                Sort Key: v1.mes, v1.ae, v1.regiao, v1.cidade, v1.cnpj_cliente
                Sort Method: quicksort  Memory: 75581kB
                Buffers: shared hit=17916
                ->  Seq Scan on public.vendedor v1  (cost=0.00..28403.31 rows=402825 width=94) (actual time=0.020..232.571 rows=405405 loops=1)
                      Output: v1.mes, v1.ae, v1.regiao, v1.cidade, v1.uf, v1.cnpj_cliente, v1.nome_rca, v1.nome_supervisor
                      Filter: ((v1.commodity)::text = 'HF'::text)
                      Rows Removed by Filter: 433580
                      Buffers: shared hit=17916
          ->  Sort  (cost=69259.51..70349.91 rows=436160 width=94) (actual time=3124.137..3207.479 rows=433760 loops=1)
                Output: v1_1.mes, v1_1.ae, v1_1.regiao, v1_1.cidade, v1_1.uf, v1_1.cnpj_cliente, v1_1.nome_rca, v1_1.nome_supervisor
                Sort Key: v1_1.mes, v1_1.ae, v1_1.regiao, v1_1.cidade, v1_1.cnpj_cliente
                Sort Method: quicksort  Memory: 80040kB
                Buffers: shared hit=17916
                ->  Seq Scan on public.vendedor v1_1  (cost=0.00..28403.31 rows=436160 width=94) (actual time=0.052..233.379 rows=433580 loops=1)
                      Output: v1_1.mes, v1_1.ae, v1_1.regiao, v1_1.cidade, v1_1.uf, v1_1.cnpj_cliente, v1_1.nome_rca, v1_1.nome_supervisor
                      Filter: ((v1_1.commodity)::text = 'PC'::text)
                      Rows Removed by Filter: 405405
                      Buffers: shared hit=17916
  ->  Sort  (cost=374912.87..374912.87 rows=1 width=2277) (actual time=2128381.174..2128443.450 rows=218279 loops=1)
        Output: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.commodity, (concat(m.cnpj (...)
        Sort Key: m.id, m.regiao, m.area_nielsen, m.ae, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.commodity, (concat(m.cnpj_cliente, ' - ', m.cl (...)
        Sort Method: quicksort  Memory: 117126kB
        Buffers: shared hit=855575640
        ->  Nested Loop  (cost=10054.26..374912.86 rows=1 width=2277) (actual time=5850.721..2121951.136 rows=218279 loops=1)
              Output: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.commodity, concat(m (...)
              Join Filter: (((m.area_nielsen)::text = (u.area_nielsen)::text) AND ((m.ae)::text = (u.ae)::text) AND ((m.cnpj_cliente)::text = (u.cnpj_cliente)::text))
              Rows Removed by Join Filter: 690603259
              Buffers: shared hit=855575640
              ->  Hash Join  (cost=9054.26..19252.27 rows=1 width=2508) (actual time=5849.511..7248.584 rows=2974 loops=1)
                    Output: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.commodity, v. (...)
                    Hash Cond: (((v.ae)::text = (m.ae)::text) AND ((v.cnpj_cliente)::text = (m.cnpj_cliente)::text) AND ((v.regiao)::text = (m.regiao)::text))
                    Buffers: shared hit=42086
                    ->  CTE Scan on vendedor_loja v  (cost=0.00..9813.60 rows=2181 width=1866) (actual time=5821.552..7123.154 rows=119307 loops=1)
                          Output: v.mes, v.ae, v.regiao, v.cidade, v.uf, v.cnpj_cliente, v.rca_hf, v.supervisor_hf, v.rca_pc, v.supervisor_pc
                          Filter: ((v.mes)::text = '2017-05'::text)
                          Rows Removed by Filter: 453181
                          Buffers: shared hit=35832
                    ->  Hash  (cost=9000.01..9000.01 rows=3100 width=918) (actual time=27.710..27.710 rows=3235 loops=1)
                          Output: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.commodi (...)
                          Buckets: 4096  Batches: 1  Memory Usage: 435kB
                          Buffers: shared hit=6254
                          ->  Gather  (cost=1000.00..9000.01 rows=3100 width=918) (actual time=11.068..25.905 rows=3235 loops=1)
                                Output: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregiao, m.c (...)
                                Workers Planned: 2
                                Workers Launched: 2
                                Buffers: shared hit=6254
                                ->  Parallel Seq Scan on public.mix_cliente_compliance m  (cost=0.00..7690.01 rows=1292 width=918) (actual time=6.406..20.979 rows=1078 loops=3)
                                      Output: m.id, m.mes, m.regiao, m.area_nielsen, m.ae, m.tipo_cliente, m.cnpj_cliente, m.qtd_itens_cobrados, m.target, m.qtd_itens_vendidos, m.faltantes, m.cliente_compliance, m.dta_inclusao, m.mesorregiao, m.microrregia (...)
                                      Filter: (((m.mes)::text = '2017-05'::text) AND ((m.tipo_cliente)::text = 'G'::text))
                                      Rows Removed by Filter: 88096
                                      Buffers: shared hit=6042
                                      Worker 0: actual time=2.038..16.904 rows=986 loops=1
                                        Buffers: shared hit=1057
                                      Worker 1: actual time=6.465..22.309 rows=1240 loops=1
                                        Buffers: shared hit=1913
              ->  Gather  (cost=1000.00..351861.31 rows=217101 width=81) (actual time=1.147..618.701 rows=232287 loops=2974)
                    Output: u.grupo, u.qtd_vendida, u.mes, u.area_nielsen, u.ae, u.cnpj_cliente, u.tipo_cliente
                    Workers Planned: 4
                    Workers Launched: 4
                    Buffers: shared hit=855533554
                    ->  Parallel Seq Scan on public.mix_relatorio_up u  (cost=0.00..329151.21 rows=54275 width=81) (actual time=0.120..609.395 rows=49265 loops=17698274)
                          Output: u.grupo, u.qtd_vendida, u.mes, u.area_nielsen, u.ae, u.cnpj_cliente, u.tipo_cliente
                          Filter: (((u.mes)::text = '2017-05'::text) AND ((u.tipo_cliente)::text = 'G'::text))
                          Rows Removed by Filter: 2304772
                          Buffers: shared hit=986029292643
                          Worker 0: actual time=0.107..610.367 rows=49900 loops=2974
                            Buffers: shared hit=166166226
                          Worker 1: actual time=0.143..608.446 rows=48508 loops=2974
                            Buffers: shared hit=164883263
                          Worker 2: actual time=0.126..608.012 rows=48364 loops=2974
                            Buffers: shared hit=164907256
                          Worker 3: actual time=0.107..610.440 rows=50049 loops=2974
                            Buffers: shared hit=166389259
    }
);
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type,                                                       'GroupAggregate', 'Properly extracted top node type' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                                     'Sort',           'Properly extracted subnode-1' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type,                   'Nested Loop',    'Properly extracted subnode-2' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 1 ]->type, 'Gather',         'Properly extracted subnode-3' );
my $gather = $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 1 ];
is( $gather->sub_nodes->[ 0 ]->type, 'Parallel Seq Scan', 'Properly extracted subnode-4' );
my $pss = $gather->sub_nodes->[ 0 ];
is( $pss->total_inclusive_time, $pss->actual_time_last * $gather->actual_loops, "Inclusive time is calculated properly for parallel nodes" );
is( $pss->total_exclusive_time, $pss->total_inclusive_time, "Exclusive time is calculated properly for parallel nodes" );

lives_ok(
    sub {
        $explain->anonymize();
    },
    'Anonymization works',
);

ok( $explain->as_text !~ /mix_cliente_compliance|mix_relatorio_up|vendedor_loja|vendedor|public/, 'anonymize() hides table names' );
ok( $explain->as_text !~ /cnpj_cliente|regiao/, 'anonymize() hides column names' );

exit;
