#!/usr/bin/env perl
# glm()'s robust covariances -- vcov => 'HC0'..'HC3', cluster => -- against
# sandwich 3.1-3's vcovHC() and vcovCL(), and against Stata.
#
# PROVENANCE
#
# %DATA and %EXPECT are frozen output of t/glm_vcov.R.R under R 4.6.1 and
# sandwich 3.1-3 (re-run with `Rscript t/glm_vcov.R.R`; it also rewrites
# t/PetersenCL.csv).  The corpora are:
#
#   pet_*     sandwich's tests/vcovCL.R: Petersen's simulated firm/year panel
#             (sandwich's PetersenCL data, shipped here as t/PetersenCL.csv),
#             the linear model -- fitted as a gaussian glm, which sandwich
#             treats identically -- and the logit on (y > 0), clustered by
#             firm and by firm and year, HC0 and HC1, and the unclustered
#             HC0 to HC3.
#   opg_*     sandwich's man/vcovOPG.Rd example, pinned in
#             tests/Examples/sandwich-Ex.Rout.save (R CMD check seeds each
#             example with set.seed(1), which reproduces it).
#   ships_*   statsmodels 0.14.6's discrete/tests/results/ships.csv, refitted
#             in R.
#   infert_*  Zou (2004), Am J Epidemiol 159:702: the "modified Poisson"
#             risk ratio -- a poisson fit to a 0/1 outcome with sandwich
#             standard errors -- on R's own infert data.
#
# Two sets of Stata figures ride along:
#
#   @STATA_PETERSEN  sandwich's tests/vcovCL.R, "comparison with Stata/MP
#                    12.0": `regress y x, vce(cluster firm)` (clm) and the
#                    brl logit (clb).  sandwich checks them with all.equal(...,
#                    tol = 1e-5) because Stata prints them to 5 figures, and
#                    so does this file.
#   %STATA_SHIPS     statsmodels 0.14.6,
#                    discrete/tests/results/results_count_robust_cluster.py:
#                    `poisson accident yr_con op_75_79` with and without
#                    exposure(service), vce(robust) and vce(cluster ship).
#                    For an ML fit Stata's vce(cluster) is vcovCL()'s HC0
#                    (G/(G-1) and no (N-1)/(N-k)) and its vce(robust) is HC0
#                    times N/(N-1), which is how statsmodels' own
#                    get_correction_factor() reconciles them; the test applies
#                    the same factors.  Stata's standard errors are evaluated
#                    at its final Newton iterate, while R's -- and so this
#                    module's -- come from the weights of the IRLS's
#                    penultimate one (see glm_irls() in LikeR.xs), which on
#                    the exposure fit is 1.6e-5 away.  So these fits are made
#                    at epsilon => 1e-14, where the two describe the same
#                    point, and held to 1e-7 relative against an observed
#                    worst of 2.5e-9 -- Stata's own stopping rule.
#
# TOLERANCE
#
# Every %EXPECT covariance element: 1e-9 relative to the largest element of
# its matrix (an off-diagonal can be near zero, so a per-element relative bound
# would be testing rounding noise).  The observed worst is printed at the end;
# it was 1.1e-13 on this build.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Stats::LikeR qw(glm);

my %DATA = (
  opg => { x => [0.8414709848078965, 0.9092974268256817, 0.1411200080598672, -0.7568024953079282, -0.9589242746631385, -0.27941549819892586, 0.6569865987187891, 0.9893582466233818, 0.4121184852417566, -0.5440211108893698, -0.9999902065507035, -0.5365729180004349, 0.4201670368266409, 0.9906073556948704, 0.6502878401571168, -0.2879033166650653, -0.9613974918795568, -0.750987246771676, 0.14987720966295234, 0.9129452507276277, 0.8366556385360561, -0.008851309290403876, -0.8462204041751706, -0.9055783620066239, -0.13235175009777303, 0.7625584504796027, 0.956375928404503, 0.27090578830786904, -0.6636338842129675, -0.9880316240928618, -0.404037645323065, 0.5514266812416906, 0.9999118601072672, 0.5290826861200238, -0.428182669496151, -0.9917788534431158, -0.6435381333569995, 0.2963685787093853, 0.9637953862840878, 0.7451131604793488, -0.158622668804709, -0.9165215479156338, -0.8317747426285983, 0.017701925105413577, 0.8509035245341184, 0.9017883476488092, 0.123573122745224, -0.7682546613236668, -0.9537526527594719, -0.26237485370392877, 0.6702291758433747, 0.9866275920404853, 0.39592515018183416, -0.5587890488516163, -0.9997551733586199, -0.5215510020869119, 0.43616475524782494, 0.9928726480845371, 0.6367380071391379, -0.3048106211022167, -0.9661177700083929, -0.7391806966492228, 0.16735570030280691, 0.9200260381967906, 0.8268286794901034, -0.026551154023966794, -0.8555199789753223, -0.8979276806892913, -0.11478481378318722, 0.7738906815578891, 0.9510546532543747, 0.25382336276203626, -0.6767719568873076, -0.9851462604682474, -0.38778163540943045, 0.5661076368981803, 0.9995201585807313, 0.5139784559875352, -0.4441126687075084, -0.9938886539233752, -0.6298879942744539, 0.31322878243308516, 0.9683644611001854, 0.7331903200732922, -0.1760756199485871, -0.9234584470040598, -0.8218178366308225, 0.03539830273366068, 0.8600694058124533, 0.8939966636005579, 0.10598751175115685, -0.7794660696158047, -0.9482821412699473, -0.24525198546765434, 0.683261714736121, 0.9835877454343449, 0.3796077390275217, -0.5733818719904229, -0.9992068341863537, -0.5063656411097588],
          y => [5, 6, 3, 3, 0, 4, 9, 8, 5, 0, 0, 0, 5, 6, 7, 2, 1, 5, 2, 9, 10, 1, 1, 0, 1, 5, 2, 3, 3, 0, 2, 5, 7, 3, 3, 1, 2, 1, 9, 5, 4, 1, 2, 3, 6, 9, 0, 1, 2, 3, 5, 10, 4, 1, 0, 0, 3, 7, 6, 2, 2, 1, 3, 6, 7, 1, 1, 2, 0, 9, 6, 5, 1, 0, 2, 8, 10, 4, 3, 3, 1, 5, 6, 4, 3, 0, 2, 1, 5, 4, 2, 0, 1, 4, 7, 9, 4, 1, 2, 2] },
  infert => { case => [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    spontaneous => [2, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 2, 1, 1, 2, 2, 2, 2, 0, 1, 0, 0, 2, 0, 2, 1, 2, 0, 1, 2, 0, 0, 1, 0, 0, 2, 0, 0, 2, 2, 2, 1, 1, 2, 2, 0, 2, 1, 2, 2, 1, 1, 2, 0, 1, 1, 2, 2, 0, 0, 1, 1, 2, 2, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 2, 0, 2, 0, 1, 0, 1, 1, 1, 0, 2, 0, 0, 2, 0, 1, 0, 0, 0, 0, 1, 2, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 2, 1, 0, 1, 1, 1, 0, 0, 1, 1],
    induced => [1, 1, 2, 2, 1, 2, 0, 0, 0, 0, 1, 2, 1, 2, 1, 2, 2, 0, 2, 0, 0, 2, 0, 0, 1, 0, 0, 0, 1, 2, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 2, 2, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 2, 0, 2, 0, 2, 1, 0, 2, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 2, 0, 1, 1, 0, 0, 0, 1, 0, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 2, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 1, 1, 2, 2, 2, 0, 1, 0, 2, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 2, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 2, 0, 0],
    stratum => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 75, 76, 77, 78, 79, 80, 81, 82, 83, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83] },
);

my %EXPECT = (
  pet_m_firm_HC0 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.004489804136864085, -6.472221646813622e-05, -6.47222164681362e-05, 0.0025594153898187383],
  },
  pet_m_fy_HC0 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.004232466619400126, -2.844774367745947e-05, -2.8447743677459475e-05, 0.0028678880146447063],
  },
  pet_b_firm_HC0 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.0035895365447660057, 1.531435682742133e-05, 1.531435682742133e-05, 0.0027576606954738936],
  },
  pet_b_fy_HC0 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.003459375517340916, -0.0002890374311004199, -0.0002890374311004199, 0.0022754211562297263],
  },
  pet_m_firm_HC1 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.00449070245701952, -6.47351660912791e-05, -6.47351660912791e-05, 0.0025599274777318676],
  },
  pet_m_fy_HC1 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.004233313451456828, -2.8453435502925152e-05, -2.8453435502925152e-05, 0.0028684618217704855],
  },
  pet_b_firm_HC1 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.0035902547393527936, 1.5317420924425617e-05, 1.5317420924425614e-05, 0.002758212448314125],
  },
  pet_b_fy_HC1 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.0034600676693051697, -0.00028909526171888746, -0.0002890952617188874, 0.002275876422567507],
  },
  pet_m_HC0 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.0008040059983244956, -1.1514366706829528e-05, -1.151436670682953e-05, 0.0008059626807125908],
  },
  pet_b_HC0 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.0009157379551288284, -4.892009626543177e-06, -4.892009626543176e-06, 0.0011732516160774884],
  },
  pet_m_HC1 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.0008043277294162641, -1.1518974296548207e-05, -1.1518974296548207e-05, 0.0008062851947905067],
  },
  pet_b_HC1 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.0009161043968875822, -4.8939672134284534e-06, -4.893967213428453e-06, 0.001173721104519299],
  },
  pet_m_HC2 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.0008043258192120753, -1.15326410682667e-05, -1.1532641068266699e-05, 0.0008066047434018885],
  },
  pet_b_HC2 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.0009160769533786832, -4.905749456931146e-06, -4.905749456931146e-06, 0.0011739230942920307],
  },
  pet_m_HC3 => {
    names => ['Intercept', 'x'],
    coef  => [0.029679720734517648, 1.0348334394616965],
    vcov  => [0.0008046458309134104, -1.1550945811923031e-05, -1.1550945811923031e-05, 0.0008072474986014444],
  },
  pet_b_HC3 => {
    names => ['Intercept', 'x'],
    coef  => [0.03594597906033545, 0.8118897554542087],
    vcov  => [0.0009164160981725615, -4.919503704954886e-06, -4.919503704954887e-06, 0.0011745949913849068],
  },
  opg_model => {
    names => ['Intercept', 'x'],
    coef  => [1.0091634925100657, 1.016722593299113],
    vcov  => [0.004526581315237335, -0.0036795696831305536, -0.0036795696831305536, 0.008110050988672901],
  },
  opg_HC0 => {
    names => ['Intercept', 'x'],
    coef  => [1.0091634925100657, 1.016722593299113],
    vcov  => [0.004077868164192258, -0.003965201693348735, -0.003965201693348736, 0.007134802438660155],
  },
  opg_HC1 => {
    names => ['Intercept', 'x'],
    coef  => [1.0091634925100657, 1.016722593299113],
    vcov  => [0.0041610899634614874, -0.004046124176886467, -0.004046124176886467, 0.007280410651694043],
  },
  opg_HC2 => {
    names => ['Intercept', 'x'],
    coef  => [1.0091634925100657, 1.016722593299113],
    vcov  => [0.004150523994830545, -0.004030805903511797, -0.004030805903511796, 0.007289713653849373],
  },
  opg_HC3 => {
    names => ['Intercept', 'x'],
    coef  => [1.0091634925100657, 1.016722593299113],
    vcov  => [0.004224537131935061, -0.004097406526810687, -0.004097406526810687, 0.007448358414266466],
  },
  ships_clu_HC1 => {
    names => ['Intercept', 'yr_con', 'op_75_79'],
    coef  => [2.269707714645867, -0.021720619045437144, 0.22148585078832847],
    vcov  => [1.2994590219388606, -0.22536740733311816, -0.06703833076716631, -0.22536740733311855, 0.042298241647718504, 0.01039218113344891, -0.06703833076716555, 0.01039218113344872, 0.013101197985924807],
  },
  ships_HC0 => {
    names => ['Intercept', 'yr_con', 'op_75_79'],
    coef  => [2.269707714645867, -0.021720619045437144, 0.22148585078832847],
    vcov  => [0.42963868459708643, -0.0930357460602974, -0.16008428751378562, -0.09303574606029738, 0.03590563797327611, -0.014764822852305959, -0.1600842875137855, -0.014764822852306025, 0.29683139672102676],
  },
  ships_exp_model => {
    names => ['Intercept', 'yr_con', 'op_75_79'],
    coef  => [-6.9747128038831985, 0.3063381955824805, 0.35592229547438076],
    vcov  => [0.017562329446754614, -0.005896415030860606, -0.0016504130328974394, -0.005896415030860606, 0.0033532662088561664, -0.003152624317535361, -0.0016504130328974394, -0.003152624317535361, 0.014766133352896118],
  },
  ships_exp_HC0 => {
    names => ['Intercept', 'yr_con', 'op_75_79'],
    coef  => [-6.9747128038831985, 0.3063381955824805, 0.35592229547438076],
    vcov  => [0.06354263484195777, -0.018060431612014895, -0.02324703788385015, -0.018060431612014913, 0.00811636507055348, 0.000958645289580397, -0.023247037883850193, 0.0009586452895804167, 0.025169632503837545],
  },
  ships_exp_clu_HC1 => {
    names => ['Intercept', 'yr_con', 'op_75_79'],
    coef  => [-6.9747128038831985, 0.3063381955824805, 0.35592229547438076],
    vcov  => [0.009987589502069676, 0.0011576993038987552, -0.0050017020259679685, 0.0011576993038987678, 0.0015517245303100166, -0.0029569365640996007, -0.005001702025968006, -0.0029569365640996085, 0.009035974941801528],
  },
  infert_HC0 => {
    names => ['Intercept', 'spontaneous', 'induced'],
    coef  => [-1.7700178982026349, 0.688491300469149, 0.262042976443361],
    vcov  => [0.03054859995437342, -0.014153222086159408, -0.012214495602185073, -0.014153222086159403, 0.009919256850624638, 0.0033637270925851543, -0.012214495602185061, 0.003363727092585151, 0.014258261945023564],
  },
  infert_clu_HC0 => {
    names => ['Intercept', 'spontaneous', 'induced'],
    coef  => [-1.7700178982026349, 0.688491300469149, 0.262042976443361],
    vcov  => [0.010843224956266157, -0.007399267924995231, -0.00513334436346868, -0.007399267924995232, 0.00862583879288899, -0.00035880295580672085, -0.0051333443634686855, -0.0003588029558067195, 0.010266609179853154],
  },
);

my @STATA_PETERSEN = (
	# regress y x, vce(cluster firm): vcovCL(m, cluster = ~ firm), HC1
	[ 'pet_m_firm_HC1', [0.0044907, -0.00006474, -0.00006474, 0.00255993] ],
	# brl binary x, cluster(firm) logit: vcovCL(b, cluster = ~ firm), HC0
	[ 'pet_b_firm_HC0', [0.00358954, 0.00001531, 0.00001531, 0.00275766] ],
);
# statsmodels results_count_robust_cluster.py, columns b and se of
# params_table, rows yr_con op_75_79 _cons.
my %STATA_SHIPS = (
	clu     => { b  => [-.02172061893549, .22148585072024, 2.2697077143215],
	             se => [.19933709357097, .11093628220713, 1.1048569901548] },
	robust  => { b  => [-.02172061893549, .22148585072024, 2.2697077143215],
	             se => [.19233713248134, .55301404772037, .66532523368388] },
	exp_model  => { b  => [.30633819450439, .35592229608495, -6.974712802772],
	                se => [.05790831365493, .12151759298719, .13252425018256] },
	exp_robust => { b  => [.30633819450439, .35592229608495, -6.974712802772],
	                se => [.09144457613957, .16103531267836, .2558675415017] },
	exp_clu    => { b  => [.30633819450439, .35592229608495, -6.974712802772],
	                se => [.03817694295902, .09213163536669, .0968656626603] },
);
my %SHIPS = (
	ship     => [1,1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5],
	yr_con   => [1,1,2,2,3,3,4,1,1,2,2,3,3,4,1,1,2,2,3,3,4,1,1,2,2,3,3,4,1,2,2,3,3,4],
	service  => [127,63,1095,1095,1512,3353,2244,44882,17176,28609,20370,7064,13099,
	             7117,1179,552,781,676,783,1948,274,251,105,288,192,349,1208,2051,45,
	             789,437,1157,2161,542],
	accident => [0,0,3,4,6,18,11,39,29,58,53,12,44,18,1,1,0,1,6,2,1,0,0,0,0,2,11,4,
	             0,7,7,5,12,1],
	op_75_79 => [0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,0,1,0,1,1],
);

# PetersenCL, as the generator wrote it.
my %PET;
{
	my $f = File::Spec->catfile('t', 'PetersenCL.csv');
	open my $fh, '<', $f or die "cannot open $f: $!";
	my $hdr = <$fh>;
	$hdr =~ s/[\r\n]+//; $hdr =~ s/"//g;
	my @c = split /,/, $hdr;
	while (my $l = <$fh>) {
		$l =~ s/[\r\n]+//;
		my @v = split /,/, $l;
		push @{ $PET{ $c[$_] } }, $v[$_] + 0 for 0 .. $#c;
	}
	close $fh;
	$PET{yb} = [ map { $_ > 0 ? 1 : 0 } @{ $PET{y} } ];
}

my %worst;
sub check_vcov {
	my ($label, $fit, $e, $tol) = @_;
	my @nm = @{ $e->{names} };
	my $p = @nm;
	my $scale = 0;
	for (@{ $e->{vcov} }) { $scale = abs($_) if abs($_) > $scale }
	my $w = 0;
	for my $i (0 .. $p - 1) {
		my $cr = abs($fit->{coefficients}{ $nm[$i] } - $e->{coef}[$i]) / abs($e->{coef}[$i]);
		$w = $cr if $cr > $w;
		for my $j (0 .. $p - 1) {
			my $got = $fit->{vcov}{ $nm[$i] }{ $nm[$j] };
			# R's vcov is column-major, and symmetric
			my $want = $e->{vcov}[ $j * $p + $i ];
			my $r = defined $got ? abs($got - $want) / $scale : 9**9**9;
			$w = $r if $r > $w;
		}
		my $se = $fit->{summary}{ $nm[$i] }{'Std. Error'};
		my $r = abs($se - sqrt($e->{vcov}[ $i * $p + $i ])) / sqrt($e->{vcov}[ $i * $p + $i ]);
		$w = $r if $r > $w;
	}
	$worst{R} = $w if !defined $worst{R} || $w > $worst{R};
	ok($w <= $tol, "$label: coefficients, vcov and standard errors match sandwich")
		or diag("worst relative disagreement $w > $tol");
}

# ------------------------------------------------------------ PetersenCL
my $m0  = glm(formula => 'y ~ x',  data => \%PET);
my $b0  = glm(formula => 'yb ~ x', data => \%PET, family => 'binomial');
for my $tp (qw(HC0 HC1)) {
	check_vcov("Petersen lm, firm, $tp", glm(formula => 'y ~ x', data => \%PET, cluster => 'firm', vcov => $tp),
	           $EXPECT{"pet_m_firm_$tp"}, 1e-9);
	check_vcov("Petersen lm, firm + year, $tp", glm(formula => 'y ~ x', data => \%PET, cluster => 'firm + year', vcov => $tp),
	           $EXPECT{"pet_m_fy_$tp"}, 1e-9);
	check_vcov("Petersen logit, firm, $tp", glm(formula => 'yb ~ x', data => \%PET, family => 'binomial', cluster => 'firm', vcov => $tp),
	           $EXPECT{"pet_b_firm_$tp"}, 1e-9);
	check_vcov("Petersen logit, firm + year, $tp", glm(formula => 'yb ~ x', data => \%PET, family => 'binomial', cluster => '~ firm + year', vcov => $tp),
	           $EXPECT{"pet_b_fy_$tp"}, 1e-9);
}
for my $tp (qw(HC0 HC1 HC2 HC3)) {
	check_vcov("Petersen lm, $tp", glm(formula => 'y ~ x', data => \%PET, vcov => $tp), $EXPECT{"pet_m_$tp"}, 1e-9);
	check_vcov("Petersen logit, $tp", glm(formula => 'yb ~ x', data => \%PET, family => 'binomial', vcov => $tp),
	           $EXPECT{"pet_b_$tp"}, 1e-9);
}
{
	# a cluster alone asks for vcovCL()'s own default for a glm, HC0
	my $f = glm(formula => 'yb ~ x', data => \%PET, family => 'binomial', cluster => 'firm');
	is($f->{'vcov.type'}, 'HC0', 'cluster without vcov => is HC0, vcovCL()\'s glm default');
	is($f->{'n.clusters'}, 500, 'n.clusters: 500 firms');
	check_vcov('Petersen logit, firm, default type', $f, $EXPECT{pet_b_firm_HC0}, 1e-9);
	my $two = glm(formula => 'y ~ x', data => \%PET, cluster => 'firm+year');
	is_deeply($two->{'n.clusters'}, [500, 10], 'multiway n.clusters lists each clustering');
	# the same clustering given by value
	my $v = glm(formula => 'yb ~ x', data => \%PET, family => 'binomial', cluster => [ @{ $PET{firm} } ]);
	check_vcov('Petersen logit, firm by value', $v, $EXPECT{pet_b_firm_HC0}, 1e-9);
}
for my $s (@STATA_PETERSEN) {
	my ($k, $V) = @$s;
	my $f = $k =~ /_m_/
		? glm(formula => 'y ~ x', data => \%PET, cluster => 'firm', vcov => 'HC1')
		: glm(formula => 'yb ~ x', data => \%PET, family => 'binomial', cluster => 'firm', vcov => 'HC0');
	my @nm = qw(Intercept x);
	my $w = 0;
	for my $i (0, 1) { for my $j (0, 1) {
		my $r = abs($f->{vcov}{ $nm[$i] }{ $nm[$j] } - $V->[ $j * 2 + $i ]) / abs($V->[ $j * 2 + $i ]);
		$w = $r if $r > $w;
	} }
	# all.equal()'s tolerance is on the mean relative difference; per element
	# the printed five figures allow 5e-5 on the smallest one
	ok($w <= 5e-3, "$k matches Stata as printed in sandwich's tests/vcovCL.R")
		or diag("worst element relative difference $w");
	my ($num, $den) = (0, 0);
	for my $i (0, 1) { for my $j (0, 1) {
		$num += abs($f->{vcov}{ $nm[$i] }{ $nm[$j] } - $V->[ $j * 2 + $i ]);
		$den += abs($V->[ $j * 2 + $i ]);
	} }
	cmp_ok($num / $den, '<=', 1e-5, "$k: all.equal(..., tol = 1e-5) as sandwich asserts it");
}

# ------------------------------------------------------------ vcovOPG corpus
check_vcov('vcovOPG example, model', glm(formula => 'y ~ x', data => $DATA{opg}, family => 'poisson'),
           $EXPECT{opg_model}, 1e-9);
{
	# and the four printed figures of tests/Examples/sandwich-Ex.Rout.save
	my $f = glm(formula => 'y ~ x', data => $DATA{opg}, family => 'poisson');
	my @printed = ([Intercept => Intercept => 0.004526581], [Intercept => x => -0.003679570],
	               [x => x => 0.008110051]);
	for my $pr (@printed) {
		my ($a, $b, $v) = @$pr;
		cmp_ok(abs($f->{vcov}{$a}{$b} - $v), '<=', 5e-10, "vcovOPG.Rd printed vcov($a, $b)");
	}
}
check_vcov("vcovOPG example, $_", glm(formula => 'y ~ x', data => $DATA{opg}, family => 'poisson', vcov => $_),
           $EXPECT{"opg_$_"}, 1e-9) for qw(HC0 HC1 HC2 HC3);

# ------------------------------------------------------------ ships
{
	my %f = (
		clu        => glm(formula => 'accident ~ yr_con + op_75_79', data => \%SHIPS, family => 'poisson',
		                  cluster => 'ship', vcov => 'HC0'),
		clu1       => glm(formula => 'accident ~ yr_con + op_75_79', data => \%SHIPS, family => 'poisson',
		                  cluster => 'ship', vcov => 'HC1'),
		robust     => glm(formula => 'accident ~ yr_con + op_75_79', data => \%SHIPS, family => 'poisson',
		                  vcov => 'HC0'),
		exp_model  => glm(formula => 'accident ~ yr_con + op_75_79 + offset(log(service))', data => \%SHIPS,
		                  family => 'poisson'),
		exp_robust => glm(formula => 'accident ~ yr_con + op_75_79', offset => 'log(service)', data => \%SHIPS,
		                  family => 'poisson', vcov => 'HC0'),
		exp_clu    => glm(formula => 'accident ~ yr_con + op_75_79 + offset(log(service))', data => \%SHIPS,
		                  family => 'poisson', cluster => 'ship'),
		exp_clu1   => glm(formula => 'accident ~ yr_con + op_75_79 + offset(log(service))', data => \%SHIPS,
		                  family => 'poisson', cluster => 'ship', vcov => 'HC1'),
	);
	check_vcov('ships, cluster HC1',  $f{clu1},       $EXPECT{ships_clu_HC1}, 1e-9);
	check_vcov('ships, HC0',          $f{robust},     $EXPECT{ships_HC0}, 1e-9);
	check_vcov('ships, exposure',     $f{exp_model},  $EXPECT{ships_exp_model}, 1e-9);
	check_vcov('ships, exposure HC0', $f{exp_robust}, $EXPECT{ships_exp_HC0}, 1e-9);
	check_vcov('ships, exposure cluster HC1', $f{exp_clu1}, $EXPECT{ships_exp_clu_HC1}, 1e-9);
	# Stata's standard errors are evaluated at its final Newton iterate, R's at
	# the IRLS's penultimate one; refit to epsilon = 1e-14 so that the two
	# describe the same point.
	for my $k (keys %f) {
		my %o = (formula => 'accident ~ yr_con + op_75_79', data => \%SHIPS, family => 'poisson',
		         epsilon => 1e-14, maxit => 100);
		$o{formula} .= ' + offset(log(service))' if $k =~ /^exp/;
		$o{cluster} = 'ship' if $k =~ /clu/;
		$o{vcov} = 'HC0' if $k =~ /robust/;
		$o{vcov} = 'HC1' if $k =~ /clu1/;
		$f{$k} = glm(%o);
	}
	my @nm = qw(yr_con op_75_79 Intercept);
	my $n = 34;
	for my $k (sort keys %STATA_SHIPS) {
		# vce(robust) for an ML fit is HC0 scaled by N/(N-1)
		my $fac = ($k =~ /robust/) ? sqrt($n / ($n - 1)) : 1;
		my $w = 0;
		for my $i (0 .. 2) {
			my $b = abs($f{$k}{coefficients}{ $nm[$i] } - $STATA_SHIPS{$k}{b}[$i]) / abs($STATA_SHIPS{$k}{b}[$i]);
			my $s = abs($f{$k}{summary}{ $nm[$i] }{'Std. Error'} * $fac - $STATA_SHIPS{$k}{se}[$i])
			        / $STATA_SHIPS{$k}{se}[$i];
			$w = $b if $b > $w;
			$w = $s if $s > $w;
		}
		$worst{Stata} = $w if !defined $worst{Stata} || $w > $worst{Stata};
		ok($w <= 1e-7, "ships $k: matches Stata (statsmodels results_count_robust_cluster.py)")
			or diag("worst relative disagreement $w");
	}
	is($f{clu}{'n.clusters'}, 5, 'ships: five clusters, as Stata\'s N_clust');
}

# ------------------------------------------------------------ modified Poisson
{
	my $f = glm(formula => 'case ~ spontaneous + induced', data => $DATA{infert}, family => 'poisson', vcov => 'HC0');
	check_vcov('infert modified Poisson, HC0', $f, $EXPECT{infert_HC0}, 1e-9);
	check_vcov('infert modified Poisson, clustered by stratum',
	           glm(formula => 'case ~ spontaneous + induced', data => $DATA{infert}, family => 'poisson',
	               cluster => 'stratum'), $EXPECT{infert_clu_HC0}, 1e-9);
	# the risk ratio and its interval come from the robust standard error
	my $se = sqrt($EXPECT{infert_HC0}{vcov}[4]);
	my $b = $EXPECT{infert_HC0}{coef}[1];
	my $z = 1.959963984540054;
	cmp_ok(abs($f->{exp}{spontaneous}{estimate} - exp($b)), '<=', 1e-12 * exp($b), 'modified Poisson: RR');
	cmp_ok(abs($f->{exp}{spontaneous}{'conf.low'} - exp($b - $z * $se)), '<=', 1e-9 * exp($b), 'modified Poisson: RR lower limit');
	cmp_ok(abs($f->{exp}{spontaneous}{'conf.high'} - exp($b + $z * $se)), '<=', 1e-9 * exp($b), 'modified Poisson: RR upper limit');
	ok(exists $f->{summary}{spontaneous}{'z value'}, 'robust summaries report z');
	my $g = glm(formula => 'y ~ x', data => \%PET, vcov => 'HC1');
	ok(exists $g->{summary}{x}{'z value'} && exists $g->{summary}{x}{'Pr(>|z|)'},
	   'a robust gaussian fit reports z too, as lmtest::coeftest() does for a glm');
	is($g->{'vcov.type'}, 'HC1', 'vcov.type records the estimator');
	is(glm(formula => 'y ~ x', data => \%PET)->{'vcov.type'}, 'model', 'vcov.type is model by default');
}

# ------------------------------------------------------------ errors
{
	my %d = (y => [1, 2, 3, 4, 5, 6], x => [1, 2, 3, 4, 6, 5], g => [qw(a a b b c c)],
	         h => ['a', 'a', 'b', undef, 'c', 'c'], one => [qw(a a a a a a)]);
	eval { glm(formula => 'y ~ x', data => \%d, vcov => 'HC4') };
	like($@, qr/vcov must be 'model', 'HC0', 'HC1', 'HC2' or 'HC3'/, 'unknown vcov croaks');
	eval { glm(formula => 'y ~ x', data => \%d, cluster => 'g', vcov => 'model') };
	like($@, qr/a cluster needs a robust vcov/, 'cluster with the model vcov croaks');
	eval { glm(formula => 'y ~ x', data => \%d, cluster => 'g', vcov => 'HC3') };
	like($@, qr/HC2\/HC3 are not available with a cluster/, 'clustered HC3 croaks');
	eval { glm(formula => 'y ~ x', data => \%d, cluster => 'h') };
	like($@, qr/cluster is missing for row '4'/, 'a missing cluster croaks, as vcovCL() does');
	eval { glm(formula => 'y ~ x', data => \%d, cluster => 'one') };
	like($@, qr/at least two distinct clusters/, 'a single cluster croaks');
	eval { glm(formula => 'y ~ x', data => \%d, cluster => 'g + g + g + g + g') };
	like($@, qr/at most 4 cluster variables/, 'five cluster variables croak');
	eval { glm(formula => 'y ~ x', data => \%d, cluster => ' + ') };
	like($@, qr/cluster names no column/, 'an empty cluster spec croaks');
}

SKIP: {
	skip 'Test::LeakTrace not installed', 2 unless eval { require Test::LeakTrace; 1 };
	my %d = (y => [1, 2, 3, 4, 5, 6, 3, 2], x => [1, 2, 3, 4, 6, 5, 2, 1],
	         g => [qw(a a b b c c d d)], h => [qw(u v u v u v u v)]);
	Test::LeakTrace::no_leaks_ok(sub {
		glm(formula => 'y ~ x', data => \%d, family => 'poisson', cluster => 'g + h', vcov => 'HC1');
	}, 'no leaks: two-way clustering');
	Test::LeakTrace::no_leaks_ok(sub {
		eval { glm(formula => 'y ~ x', data => \%d, cluster => 'g', vcov => 'HC2') };
	}, 'no leaks: croak on clustered HC2');
}

diag(sprintf('worst relative disagreement against %s: %.3g', $_, $worst{$_})) for sort keys %worst;
done_testing();
