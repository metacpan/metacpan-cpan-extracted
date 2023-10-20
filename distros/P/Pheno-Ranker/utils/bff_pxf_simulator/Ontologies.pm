package Ontologies;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw( $hpo_array $omim_array $rxnorm_array $ethnicity_array);

# Hard-coded for the sake of speed
# 100 random entries
our $hpo_array = [
    { id => 'HP:0000020', label => 'Urinary incontinence' },
    { id => 'HP:0000055', label => 'Abnormality of female external genitalia' },
    { id => 'HP:0000141', label => 'Amenorrhea' },
    { id => 'HP:0000553', label => 'Abnormal uvea morphology' },
    { id => 'HP:0000630', label => 'Abnormal retinal artery morphology' },
    { id => 'HP:0000632', label => 'Lacrimation abnormality' },
    { id => 'HP:0000729', label => 'Autistic behavior' },
    { id => 'HP:0000953', label => 'Hyperpigmentation of the skin' },
    { id => 'HP:0001300', label => 'Parkinsonism' },
    {
        id    => 'HP:0001471',
        label => 'Aplasia/Hypoplasia of the musculature of the pelvis'
    },
    { id => 'HP:0001473', label => 'Metatarsal osteolysis' },
    { id => 'HP:0001609', label => 'Hoarse voice' },
    { id => 'HP:0001629', label => 'Ventricular septal defect' },
    { id => 'HP:0001730', label => 'Progressive hearing impairment' },
    { id => 'HP:0001874', label => 'Abnormality of neutrophils' },
    { id => 'HP:0002123', label => 'Generalized myoclonic seizure' },
    { id => 'HP:0002418', label => 'Abnormal midbrain morphology' },
    { id => 'HP:0002597', label => 'Abnormality of the vasculature' },
    { id => 'HP:0002857', label => 'Genu valgum' },
    { id => 'HP:0002863', label => 'Myelodysplasia' },
    {
        id    => 'HP:0002963',
        label => 'Abnormal delayed hypersensitivity skin test'
    },
    { id => 'HP:0003174', label => 'Abnormality of the ischium' },
    { id => 'HP:0003366', label => 'Abnormal femoral neck/head morphology' },
    { id => 'HP:0003963', label => 'Lytic defects of the forearm bones' },
    { id => 'HP:0004150', label => 'Abnormal 3rd finger morphology' },
    {
        id    => 'HP:0004362',
        label => 'Abnormality of enteric ganglion morphology'
    },
    { id => 'HP:0004736', label => 'Crossed fused renal ectopia' },
    { id => 'HP:0005035', label => 'Shortening of all phalanges of the toes' },
    { id => 'HP:0005656', label => 'Positional foot deformity' },
    { id => 'HP:0005830', label => 'Flexion contracture of toe' },
    {
        id    => 'HP:0006817',
        label => 'Aplasia/Hypoplasia of the cerebellar vermis'
    },
    { id => 'HP:0007400', label => 'Irregular hyperpigmentation' },
    { id => 'HP:0008066', label => 'Abnormal blistering of the skin' },
    { id => 'HP:0008264', label => 'Neutrophil inclusion bodies' },
    {
        id    => 'HP:0009138',
        label => 'Synostosis involving bones of the lower limbs'
    },
    { id => 'HP:0009404', label => 'Broad phalanges of the 4th finger' },
    { id => 'HP:0009412', label => 'Cone-shaped epiphyses of the 3rd finger' },
    {
        id    => 'HP:0009421',
        label => 'Aplasia/Hypoplasia of the distal phalanx of the 3rd finger'
    },
    { id => 'HP:0009489', label => 'Bracket epiphyses of the 2nd finger' },
    {
        id    => 'HP:0009500',
        label =>
          'Abnormality of the epiphysis of the middle phalanx of the 2nd finger'
    },
    {
        id    => 'HP:0009618',
        label => 'Abnormality of the proximal phalanx of the thumb'
    },
    { id => 'HP:0009810', label => 'Abnormality of upper limb joint' },
    { id => 'HP:0010160', label => 'Abnormal toe epiphysis morphology' },
    { id => 'HP:0010178', label => 'Patchy sclerosis of toe phalanx' },
    {
        id    => 'HP:0010250',
        label =>
          'Fragmentation of the epiphyses of the distal phalanges of the hand'
    },
    { id => 'HP:0010501', label => 'Limitation of knee mobility' },
    { id => 'HP:0010514', label => 'Hyperpituitarism' },
    { id => 'HP:0010784', label => 'Uterine neoplasm' },
    { id => 'HP:0010841', label => 'Multifocal epileptiform discharges' },
    {
        id    => 'HP:0010930',
        label => 'Abnormal blood monovalent inorganic cation concentration'
    },
    { id => 'HP:0010969', label => 'Abnormality of glycolipid metabolism' },
    { id => 'HP:0011037', label => 'Decreased urine output' },
    { id => 'HP:0011123', label => 'Inflammatory abnormality of the skin' },
    { id => 'HP:0011176', label => 'EEG with constitutional variants' },
    { id => 'HP:0011315', label => 'Unicoronal synostosis' },
    { id => 'HP:0011488', label => 'Abnormal corneal endothelium morphology' },
    { id => 'HP:0011636', label => 'Abnormal coronary artery origin' },
    { id => 'HP:0012034', label => 'Liposarcoma' },
    {
        id    => 'HP:0012092',
        label => 'Abnormality of exocrine pancreas physiology'
    },
    { id => 'HP:0012210', label => 'Abnormal renal morphology' },
    { id => 'HP:0012310', label => 'Abnormal monocyte count' },
    { id => 'HP:0012780', label => 'Neoplasm of the ear' },
    { id => 'HP:0012836', label => 'Spatial pattern' },
    { id => 'HP:0025429', label => 'Abnormal cry' },
    { id => 'HP:0025487', label => 'Abnormality of bladder morphology' },
    { id => 'HP:0025592', label => 'Superior oblique muscle weakness' },
    { id => 'HP:0025646', label => 'Bilateral polymicrogyria' },
    { id => 'HP:0030047', label => 'Abnormal lateral ventricle morphology' },
    { id => 'HP:0030113', label => 'Abnormal muscle fiber dysferlin' },
    { id => 'HP:0030119', label => 'Abnormal muscle fiber calpain-3' },
    { id => 'HP:0030493', label => 'Abnormality of foveal pigmentation' },
    { id => 'HP:0030604', label => 'Abnormal fundus fluorescein angiography' },
    { id => 'HP:0030746', label => 'Intraventricular hemorrhage' },
    { id => 'HP:0030828', label => 'Wheezing' },
    { id => 'HP:0031607', label => 'Pelvic organ prolapse' },
    { id => 'HP:0031704', label => 'Abnormal ear physiology' },
    { id => 'HP:0031753', label => 'Medial rectus muscle weakness' },
    { id => 'HP:0032011', label => 'Heterophoria' },
    { id => 'HP:0032184', label => 'Increased proportion of memory T cells' },
    { id => 'HP:0032422', label => 'Abnormal HDL2b concentration' },
    { id => 'HP:0032900', label => 'Focal manual automatism seizure' },
    {
        id    => 'HP:0033095',
        label => 'Increased sulfur amino acid level in urine'
    },
    { id => 'HP:0033823', label => 'Mediastinal mass' },
    { id => 'HP:0034022', label => 'Anti-HLA-B antibody positivity' },
    { id => 'HP:0040195', label => 'Decreased head circumference' },
    { id => 'HP:0100569', label => 'Abnormally ossified vertebrae' },
    { id => 'HP:0100612', label => 'Odontogenic neoplasm' },
    { id => 'HP:0200040', label => 'Epidermoid cyst' },
    { id => 'HP:0200042', label => 'Skin ulcer' },
    { id => 'HP:0200065', label => 'Chorioretinal degeneration' },
    { id => 'HP:0200114', label => 'Metabolic alkalosis' },
    { id => 'HP:0200160', label => 'Agenesis of maxillary incisor' },
    { id => 'HP:0410033', label => 'Unilateral alveolar cleft of maxilla' },
    { id => 'HP:0500020', label => 'Abnormal cardiac biomarker test' },
    { id => 'HP:0500073', label => 'Abnormal ocular alignment' },
    { id => 'HP:0500093', label => 'Food allergy' },
    {
        id    => 'HP:0500155',
        label => 'Abnormal circulating asparagine concentration'
    },
    {
        id    => 'HP:0500158',
        label => 'Abnormal circulating aspartic acid concentration'
    },
    {
        id    => 'HP:5200018',
        label => 'Abnormal movements of the upper extremities'
    },
    { id => 'HP:5200027', label => 'Abnormal social initiation' }
];

# 100 random entries
our $omim_array = [
    { id => 'OMIM:101000', label => 'Neurofibromatosis, type 2' },
    { id => 'OMIM:102578', label => 'Leukemia, acute promyelocytic, somatic' },
    { id => 'OMIM:103050', label => 'Adenylosuccinase deficiency' },
    {
        id    => 'OMIM:103900',
        label => 'Aldosteronism, glucocorticoid-remediable'
    },
    { id => 'OMIM:104200', label => 'Alport syndrome, autosomal dominant' },
    { id => 'OMIM:104300', label => 'Alzheimer disease, susceptibility to' },
    { id => 'OMIM:105120', label => 'Amyloidosis, Finnish type' },
    { id => 'OMIM:105400', label => 'Amyotrophic lateral sclerosis 1' },
    { id => 'OMIM:105800', label => 'Aneurysm, intracranial berry, 1' },
    { id => 'OMIM:105830', label => 'Angelman syndrome' },
    { id => 'OMIM:108725', label => 'Atherosclerosis, susceptibility to' },
    { id => 'OMIM:108800', label => 'Atrial septal defect 1' },
    { id => 'OMIM:109800', label => 'Bladder cancer, somatic' },
    { id => 'OMIM:111200', label => 'Blood group, Auberger system' },
    { id => 'OMIM:111200', label => 'Blood group, Lutheran system' },
    { id => 'OMIM:111250', label => 'Blood group, Landsteiner-Wiener' },
    { id => 'OMIM:111800', label => 'Blood group, Stoltzfus system' },
    { id => 'OMIM:112100', label => 'Blood group, Yt system' },
    { id => 'OMIM:113970', label => 'Burkitt lymphoma' },
    {
        id    => 'OMIM:114500',
        label => 'Colonic adenoma recurrence, reduced risk of'
    },
    { id => 'OMIM:114500', label => 'Colorectal cancer, susceptibility to' },
    { id => 'OMIM:114550', label => 'Hepatocellular carcinoma, somatic' },
    { id => 'OMIM:115665', label => 'Cataract 8, multiple types' },
    { id => 'OMIM:118450', label => 'Alagille syndrome 1' },
    { id => 'OMIM:121400', label => 'Cornea plana 1, autosomal dominant' },
    { id => 'OMIM:123320', label => 'Creatine phosphokinase, elevated serum' },
    { id => 'OMIM:125264', label => 'Leukemia, acute nonlymphocytic' },
    { id => 'OMIM:125853', label => 'Diabetes, type 2, susceptibility to' },
    { id => 'OMIM:125853', label => 'Insulin resistance, susceptibility to' },
    { id => 'OMIM:127300', label => 'Leri-Weill dyschondrosteosis' },
    { id => 'OMIM:127750', label => 'Lewy body dementia, susceptibility to' },
    { id => 'OMIM:130050', label => 'Ehlers-Danlos syndrome, type IV' },
    { id => 'OMIM:130060', label => 'Ehlers-Danlos syndrome, type VIIB' },
    { id => 'OMIM:130650', label => 'Beckwith-Wiedemann syndrome' },
    { id => 'OMIM:131100', label => 'Multiple endocrine neoplasia 1' },
    { id => 'OMIM:132100', label => 'Photoparoxysmal response 1' },
    { id => 'OMIM:133700', label => 'Exostoses, multiple, type 1' },
    { id => 'OMIM:134610', label => 'Familial Mediterranean fever, AD' },
    { id => 'OMIM:136120', label => 'Fish-eye disease' },
    {
        id    => 'OMIM:137215',
        label => 'Gastric cancer risk after H. pylori infection'
    },
    { id => 'OMIM:137550', label => 'Spitz nevus or nevus spilus, somatic' },
    { id => 'OMIM:137580', label => 'Tourette syndrome' },
    { id => 'OMIM:139300', label => 'Aromatase excess syndrome' },
    { id => 'OMIM:140700', label => 'Heinz body anemias, beta-' },
    { id => 'OMIM:141200', label => 'Hematuria, benign familial' },
    { id => 'OMIM:141749', label => 'Delta-beta thalassemia' },
    {
        id    => 'OMIM:141749',
        label => 'Hereditary persistence of fetal hemoglobin'
    },
    { id => 'OMIM:142335', label => 'Fetal hemoglobin QTL5' },
    { id => 'OMIM:142945', label => 'Holoprosencephaly 3' },
    { id => 'OMIM:143100', label => 'Huntington disease' },
    {
        id    => 'OMIM:143465',
        label => 'Attention deficit-hyperactivity disorder'
    },
    {
        id    => 'OMIM:143465',
        label => 'Attention deficit-hyperactivity disorder, susceptibility to'
    },
    { id => 'OMIM:143890', label => 'Hypercholesterolemia, familial' },
    { id => 'OMIM:143890', label => 'LDL cholesterol level QTL2' },
    { id => 'OMIM:144650', label => 'Hyperchylomicronemia, late-onset' },
    { id => 'OMIM:144700', label => 'Renal cell carcinoma' },
    { id => 'OMIM:145750', label => 'Hypertriglyceridemia, susceptibility to' },
    { id => 'OMIM:146200', label => 'Hypoparathyroidism, autosomal dominant' },
    { id => 'OMIM:146200', label => 'Hypoparathyroidism, autosomal recessive' },
    { id => 'OMIM:146510', label => 'Pallister-Hall syndrome' },
    { id => 'OMIM:147050', label => 'Atopy, susceptibility to' },
    { id => 'OMIM:147050', label => 'IgE, elevated level of' },
    { id => 'OMIM:147250', label => 'Single median maxillary central incisor' },
    { id => 'OMIM:147791', label => 'Jacobsen syndrome' },
    { id => 'OMIM:150699', label => 'Leiomyoma, uterine, somatic' },
    { id => 'OMIM:152700', label => 'Lupus nephritis, susceptibility to' },
    { id => 'OMIM:154800', label => 'Mast cell disease' },
    { id => 'OMIM:155240', label => 'Medullary thyroid carcinoma, familial' },
    { id => 'OMIM:155600', label => 'Melanoma, cutaneous malignant, 1' },
    {
        id    => 'OMIM:157300',
        label => 'Migraine without aura, susceptibility to'
    },
    { id => 'OMIM:159900', label => 'Dystonia-11, myoclonic' },
    { id => 'OMIM:160900', label => 'Myotonic dystrophy 1' },
    { id => 'OMIM:162091', label => 'Schwannomatosis' },
    {
        id    => 'OMIM:162900',
        label => 'Nevus sebaceous or woolly hair nevus, somatic'
    },
    {
        id    => 'OMIM:163200',
        label => 'Schimmelpenning-Feuerstein-Mims syndrome, somatic mosaic'
    },
    { id => 'OMIM:166210', label => 'Osteogenesis imperfecta, type II' },
    { id => 'OMIM:166220', label => 'Osteogenesis imperfecta, type IV' },
    { id => 'OMIM:166710', label => 'Osteoporosis, postmenopausal' },
    {
        id    => 'OMIM:166710',
        label => 'Osteoporosis, postmenopausal, susceptibility'
    },
    { id => 'OMIM:167210', label => 'Pachyonychia congenita 2' },
    { id => 'OMIM:167800', label => 'Pancreatitis, hereditary' },
    { id => 'OMIM:167800', label => 'Pancreatitis, idiopathic' },
    {
        id    => 'OMIM:168600',
        label => 'Parkinson disease, late-onset, susceptibility to'
    },
    { id => 'OMIM:168600', label => 'Parkinson disease, susceptibility to' },
    { id => 'OMIM:170100', label => 'Prolidase deficiency' },
    { id => 'OMIM:171300', label => 'Pheochromocytoma, susceptibility to' },
    { id => 'OMIM:172700', label => 'Pick disease' },
    { id => 'OMIM:172800', label => 'Piebaldism' },
    { id => 'OMIM:174000', label => 'Medullary cystic kidney disease 1' },
    { id => 'OMIM:174200', label => 'Polydactyly, postaxial, types A1 and B' },
    { id => 'OMIM:174700', label => 'Polydactyly, preaxial, type IV' },
    { id => 'OMIM:175700', label => 'Greig cephalopolysyndactyly syndrome' },
    { id => 'OMIM:176310', label => 'Leukemia, acute pre-B-cell' },
    { id => 'OMIM:176807', label => 'Prostate cancer, hereditary' },
    { id => 'OMIM:177700', label => 'Glaucoma 1, open angle, P' },
    {
        id    => 'OMIM:178500',
        label => 'Pulmonary fibrosis, idiopathic, susceptibility to'
    },
    { id => 'OMIM:180105', label => 'Retinitis pigmentosa 10' },
    { id => 'OMIM:180385', label => 'Leukemia, acute T-cell' },
    { id => 'OMIM:180849', label => 'Rubinstein-Taybi syndrome' },
    { id => 'OMIM:180860', label => 'Silver-Russell syndrome' }
];

# 100 random entries
our $rxnorm_array = [
    {
        id    => 'RxNorm:1000000',
        label =>
'amlodipine 5 MG / hydrochlorothiazide 12.5 MG / olmesartan medoxomil 40 MG Oral Tablet [Tribenzor]'
    },
    {
        id    => 'RxNorm:1000001',
        label =>
'amlodipine 5 MG / hydrochlorothiazide 25 MG / olmesartan medoxomil 40 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000005',
        label =>
'amlodipine 5 MG / hydrochlorothiazide 25 MG / olmesartan medoxomil 40 MG Oral Tablet [Tribenzor]'
    },
    {
        id    => 'RxNorm:1000009',
        label =>
'dimethicone 100 MG/ML / miconazole nitrate 20 MG/ML / zinc oxide 100 MG/ML Topical Spray'
    },
    { id => 'RxNorm:1000048', label => 'doxepin 10 MG Oral Capsule' },
    { id => 'RxNorm:1000054', label => 'doxepin 10 MG/ML Oral Solution' },
    { id => 'RxNorm:1000058', label => 'doxepin 100 MG Oral Capsule' },
    { id => 'RxNorm:1000064', label => 'doxepin 150 MG Oral Capsule' },
    { id => 'RxNorm:1000070', label => 'doxepin 25 MG Oral Capsule' },
    { id => 'RxNorm:1000076', label => 'doxepin 50 MG Oral Capsule' },
    {
        id    => 'RxNorm:1000085',
        label => 'alcaftadine 2.5 MG/ML Ophthalmic Solution'
    },
    {
        id    => 'RxNorm:1000089',
        label => 'alcaftadine 2.5 MG/ML Ophthalmic Solution [Lastacaft]'
    },
    {
        id    => 'RxNorm:1000091',
        label => 'doxepin hydrochloride 50 MG/ML Topical Cream'
    },
    {
        id    => 'RxNorm:1000093',
        label => 'doxepin hydrochloride 50 MG/ML Topical Cream [Prudoxin]'
    },
    {
        id    => 'RxNorm:1000095',
        label => 'doxepin hydrochloride 50 MG/ML Topical Cream [Zonalon]'
    },
    { id => 'RxNorm:1000097', label => 'doxepin 75 MG Oral Capsule' },
    {
        id    => 'RxNorm:1000107',
        label => 'incobotulinumtoxinA 200 UNT Injection'
    },
    {
        id    => 'RxNorm:1000114',
        label => 'medroxyprogesterone acetate 10 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000124',
        label => 'medroxyprogesterone acetate 10 MG Oral Tablet [Provera]'
    },
    {
        id    => 'RxNorm:1000126',
        label => '1 ML medroxyprogesterone acetate 150 MG/ML Injection'
    },
    {
        id    => 'RxNorm:1000128',
        label =>
          '1 ML medroxyprogesterone acetate 150 MG/ML Injection [Depo-Provera]'
    },
    {
        id    => 'RxNorm:1000131',
        label => 'medroxyprogesterone acetate 400 MG/ML Injectable Suspension'
    },
    {
        id    => 'RxNorm:1000133',
        label =>
'medroxyprogesterone acetate 400 MG/ML Injectable Suspension [Depo-Provera]'
    },
    {
        id    => 'RxNorm:1000135',
        label => 'medroxyprogesterone acetate 2.5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000139',
        label => 'medroxyprogesterone acetate 2.5 MG Oral Tablet [Provera]'
    },
    {
        id    => 'RxNorm:1000141',
        label => 'medroxyprogesterone acetate 5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000145',
        label => 'medroxyprogesterone acetate 5 MG Oral Tablet [Provera]'
    },
    {
        id    => 'RxNorm:1000153',
        label => '1 ML medroxyprogesterone acetate 150 MG/ML Prefilled Syringe'
    },
    {
        id    => 'RxNorm:1000154',
        label =>
'1 ML medroxyprogesterone acetate 150 MG/ML Prefilled Syringe [Depo-Provera]'
    },
    {
        id    => 'RxNorm:1000156',
        label =>
          '0.65 ML medroxyprogesterone acetate 160 MG/ML Prefilled Syringe'
    },
    {
        id    => 'RxNorm:1000158',
        label =>
'0.65 ML medroxyprogesterone acetate 160 MG/ML Prefilled Syringe [depo-subQ provera]'
    },
    {
        id    => 'RxNorm:1000351',
        label =>
'estrogens, conjugated (USP) 0.3 MG / medroxyprogesterone acetate 1.5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000352',
        label =>
'estrogens, conjugated (USP) 0.45 MG / medroxyprogesterone acetate 1.5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000355',
        label =>
'estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 2.5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000356',
        label =>
'estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000395',
        label =>
'{28 (estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 2.5 MG Oral Tablet) } Pack'
    },
    {
        id    => 'RxNorm:1000398',
        label =>
'{28 (estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 5 MG Oral Tablet) } Pack'
    },
    {
        id    => 'RxNorm:1000405',
        label => 'norethindrone acetate 5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000407',
        label => 'norethindrone acetate 5 MG Oral Tablet [Aygestin]'
    },
    {
        id    => 'RxNorm:1000479',
        label =>
'{1 (bisacodyl 5 MG Delayed Release Oral Tablet) / 1 (2000 ML) (polyethylene glycol 3350 210000 MG / potassium chloride 740 MG / sodium bicarbonate 2860 MG / sodium chloride 5600 MG Powder for Oral Solution) } Pack'
    },
    {
        id    => 'RxNorm:1000486',
        label =>
'{14 (estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 5 MG Oral Tablet) / 14 (estrogens, conjugated (USP) 0.625 MG Oral Tablet) } Pack'
    },
    {
        id    => 'RxNorm:1000487',
        label =>
'{14 (estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 5 MG Oral Tablet) / 14 (estrogens, conjugated (USP) 0.625 MG Oral Tablet) } Pack [Premphase 28 Day]'
    },
    {
        id    => 'RxNorm:1000490',
        label =>
'{28 (estrogens, conjugated (USP) 0.3 MG / medroxyprogesterone acetate 1.5 MG Oral Tablet) } Pack'
    },
    {
        id    => 'RxNorm:1000491',
        label =>
'{28 (estrogens, conjugated (USP) 0.3 MG / medroxyprogesterone acetate 1.5 MG Oral Tablet) } Pack [Prempro 0.3/1.5 28 Day]'
    },
    { id => 'RxNorm:1000495', label => 'resveratrol 250 MG Oral Capsule' },
    {
        id    => 'RxNorm:1000496',
        label =>
'{28 (estrogens, conjugated (USP) 0.45 MG / medroxyprogesterone acetate 1.5 MG Oral Tablet) } Pack'
    },
    {
        id    => 'RxNorm:1000497',
        label =>
'{28 (estrogens, conjugated (USP) 0.45 MG / medroxyprogesterone acetate 1.5 MG Oral Tablet) } Pack [Prempro 0.45/1.5 28 Day]'
    },
    {
        id    => 'RxNorm:1000499',
        label =>
'{28 (estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 2.5 MG Oral Tablet) } Pack [Prempro 0.625/2.5 28 Day]'
    },
    {
        id    => 'RxNorm:1000500',
        label =>
'{28 (estrogens, conjugated (USP) 0.625 MG / medroxyprogesterone acetate 5 MG Oral Tablet) } Pack [Prempro 0.625/5 28 Day]'
    },
    {
        id    => 'RxNorm:1000502',
        label =>
'dextromethorphan hydrobromide 6 MG/ML / guaifenesin 40 MG/ML / phenylephrine hydrochloride 1.5 MG/ML Oral Solution'
    },
    {
        id    => 'RxNorm:1000556',
        label =>
'fluorometholone 1 MG/ML / sulfacetamide sodium 100 MG/ML Ophthalmic Suspension'
    },
    {
        id    => 'RxNorm:1000558',
        label =>
'fluorometholone 1 MG/ML / sulfacetamide sodium 100 MG/ML Ophthalmic Suspension [FML-S]'
    },
    {
        id    => 'RxNorm:1000636',
        label => 'dimethicone 12.5 MG/ML Topical Lotion'
    },
    {
        id    => 'RxNorm:1000647',
        label => 'pilocarpine hydrochloride 10 MG/ML Ophthalmic Solution'
    },
    {
        id    => 'RxNorm:1000656',
        label =>
'pilocarpine hydrochloride 10 MG/ML Ophthalmic Solution [Isoptocarpine]'
    },
    {
        id    => 'RxNorm:1000660',
        label =>
          'pilocarpine hydrochloride 10 MG/ML Ophthalmic Solution [Pilocar]'
    },
    {
        id    => 'RxNorm:1000673',
        label => 'sulfacetamide sodium 0.1 MG/MG Ophthalmic Ointment'
    },
    {
        id    => 'RxNorm:1000713',
        label => 'sulfacetamide sodium 0.1 MG/MG Topical Gel'
    },
    {
        id    => 'RxNorm:1000720',
        label =>
'sulfacetamide sodium 100 MG/ML / sulfur 10 MG/ML Medicated Liquid Soap [BP 10-Wash]'
    },
    {
        id    => 'RxNorm:1000731',
        label =>
          'sulfacetamide sodium 100 MG/ML / sulfur 20 MG/ML Topical Cream'
    },
    {
        id    => 'RxNorm:1000736',
        label =>
'sulfacetamide sodium 100 MG/ML / sulfur 20 MG/ML Topical Cream [Avar]'
    },
    {
        id    => 'RxNorm:1000859',
        label =>
'sulfacetamide sodium 100 MG/ML / sulfur 40 MG/ML Medicated Liquid Soap'
    },
    {
        id    => 'RxNorm:1000861',
        label =>
'sulfacetamide sodium 100 MG/ML / sulfur 40 MG/ML Medicated Liquid Soap [BP Cleansing Wash]'
    },
    {
        id    => 'RxNorm:1000862',
        label => 'pilocarpine hydrochloride 20 MG/ML Ophthalmic Solution'
    },
    {
        id    => 'RxNorm:1000870',
        label =>
'pilocarpine hydrochloride 20 MG/ML Ophthalmic Solution [Isoptocarpine]'
    },
    {
        id    => 'RxNorm:1000876',
        label =>
          'pilocarpine hydrochloride 20 MG/ML Ophthalmic Solution [Pilocar]'
    },
    {
        id    => 'RxNorm:1000895',
        label =>
'sulfacetamide sodium 100 MG/ML / sulfur 20 MG/ML Medicated Liquid Soap'
    },
    {
        id    => 'RxNorm:1000897',
        label => 'pilocarpine hydrochloride 40 MG/ML Ophthalmic Solution'
    },
    {
        id    => 'RxNorm:1000903',
        label =>
'pilocarpine hydrochloride 40 MG/ML Ophthalmic Solution [Isoptocarpine]'
    },
    {
        id    => 'RxNorm:1000907',
        label =>
          'pilocarpine hydrochloride 40 MG/ML Ophthalmic Solution [Pilocar]'
    },
    {
        id    => 'RxNorm:1000913',
        label => 'pilocarpine hydrochloride 5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1000915',
        label => 'pilocarpine hydrochloride 5 MG Oral Tablet [Salagen]'
    },
    {
        id    => 'RxNorm:1000946',
        label =>
          'sulfacetamide sodium 100 MG/ML / sulfur 40 MG/ML Medicated Pad'
    },
    {
        id    => 'RxNorm:1000976',
        label =>
'sulfacetamide sodium 100 MG/ML / sulfur 40 MG/ML Medicated Pad [Sumaxin]'
    },
    {
        id    => 'RxNorm:1000981',
        label => 'oxymetazoline hydrochloride 0.25 MG/ML Ophthalmic Solution'
    },
    {
        id    => 'RxNorm:1000990',
        label => 'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray'
    },
    {
        id    => 'RxNorm:1000992',
        label => 'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Afrin]'
    },
    {
        id    => 'RxNorm:1000994',
        label =>
'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Allerest 12 Hour Nasal Spray]'
    },
    {
        id    => 'RxNorm:1000996',
        label =>
'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Dristan 12-Hour Nasal Spray]'
    },
    {
        id    => 'RxNorm:1001002',
        label =>
          'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Duramist Plus]'
    },
    {
        id    => 'RxNorm:1001004',
        label => 'pilocarpine hydrochloride 7.5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1001006',
        label => 'pilocarpine hydrochloride 7.5 MG Oral Tablet [Salagen]'
    },
    {
        id    => 'RxNorm:1001054',
        label =>
'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Neo-Synephrine 12 Hour]'
    },
    {
        id    => 'RxNorm:1001058',
        label => 'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Nostrilla]'
    },
    {
        id    => 'RxNorm:1001066',
        label =>
'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Sinex Long-Acting]'
    },
    {
        id    => 'RxNorm:1001084',
        label =>
'oxymetazoline hydrochloride 0.5 MG/ML Nasal Spray [Zicam Sinus Relief]'
    },
    {
        id    => 'RxNorm:1001405',
        label => 'docetaxel 20 MG/ML Injectable Solution'
    },
    {
        id    => 'RxNorm:1001409',
        label => 'calcium carbonate 625 MG / ergocalciferol 125 UNT Oral Tablet'
    },
    {
        id    => 'RxNorm:1001433',
        label => '1.5 ML cabazitaxel 40 MG/ML Injection'
    },
    {
        id    => 'RxNorm:1001437',
        label => 'caffeine 50 MG / magnesium salicylate 162.5 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1001476',
        label => 'aspirin 325 MG Delayed Release Oral Tablet [Ecpirin]'
    },
    {
        id    => 'RxNorm:1001591',
        label =>
          'fibrinogen, human 337 MG / thrombin, human 123 UNT Medicated Patch'
    },
    {
        id    => 'RxNorm:1001593',
        label =>
'fibrinogen, human 337 MG / thrombin, human 123 UNT Medicated Patch [TachoSil]'
    },
    {
        id    => 'RxNorm:1001679',
        label =>
'calcium carbonate 400 MG / cholecalciferol 133 UNT / magnesium oxide 167 MG Oral Tablet'
    },
    {
        id    => 'RxNorm:1001689',
        label =>
'{2 (480 ML) (magnesium sulfate 0.0277 MEQ/ML / potassium sulfate 0.0374 MEQ/ML / sodium sulfate 0.257 MEQ/ML Oral Solution) } Pack'
    },
    {
        id    => 'RxNorm:1001690',
        label =>
'{2 (480 ML) (magnesium sulfate 0.0277 MEQ/ML / potassium sulfate 0.0374 MEQ/ML / sodium sulfate 0.257 MEQ/ML Oral Solution) } Pack [Suprep Bowel Prep Kit]'
    },
    {
        id    => 'RxNorm:1001691',
        label =>
'calcium carbonate 1250 MG / cholecalciferol 100 UNT / vitamin K1 0.04 MG Chewable Tablet'
    },
    {
        id    => 'RxNorm:1001714',
        label =>
'sulfacetamide sodium 90 MG/ML / sulfur 40 MG/ML Medicated Liquid Soap'
    },
    {
        id    => 'RxNorm:1001718',
        label =>
'sulfacetamide sodium 90 MG/ML / sulfur 40 MG/ML Medicated Liquid Soap [Zencia Wash]'
    },
    {
        id    => 'RxNorm:1001751',
        label => 'calcium citrate 250 MG / cholecalciferol 100 UNT Oral Tablet'
    }
];

# mrueda
our $ethnicity_array = [
    { id => 'NCIT:C42331', label => 'African' },
    { id => 'NCIT:C67109', label => 'Multiracial' },
    { id => 'NCIT:C16352', label => 'Black or African American' },
    { id => 'NCIT:C41261', label => 'White' },
    { id => 'NCIT:C41260', label => 'Asian' },
    { id => 'NCIT:C17459', label => 'Hispanic or Latino' }
];
1;
