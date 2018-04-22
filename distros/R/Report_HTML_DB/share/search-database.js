
/**
 * File with actions of the website
 * 
 * @author Wendel Hime Lino Castro
 */

var idForm = "";
var pageSize = 10;
var offset = 1;
var totalValues = 10;

/**
 * method used to verify paged responses
 * @param acientID ancient id
 * @param actualID id of actual form
 * @returns status
 */
function verifyPagedResponse(acientID, actualID, values) {
    var status = false;
    var numberOfPages = 0;
    $("#totalResults").show();
    $("#totalResults").text("Found " + totalValues + " results");
    if (totalValues <= 10) {
        numberOfPages = 1;
    } else {
        var number = (values / pageSize);
        if (Math.round(number) - number > 0) {
            numberOfPages = Math.round(number);
        } else {
            numberOfPages = Math.round(number + 1);
        }
        //    	var number = (values  + pageSize - 1) / pageSize;
        //    	if(Math.round(number) - number > 0) {
        //    		numberOfPages = Math.round(number);
        //    	} else {
        //    		numberOfPages = Math.trunc(number);
        //    	}
    }
    $("#numberPage").attr("max", numberOfPages);
    $("#totalNumberPages").text(numberOfPages);
    if (parseInt($("#numberPage").val()) > parseInt($("#totalNumberPages").text())) {
        $("#numberPage").val(1);
    }
    if (acientID == actualID) {
        if ((totalValues - offset) <= pageSize && ($("#numberPage").val() == $("#totalNumberPages").text())) {
            $("#more").attr("disabled", "disabled");
            $("#last").attr("disabled", "disabled");

        } else {
            $("#more").removeAttr("disabled");
            $("#last").removeAttr("disabled");
        }
        if (offset <= 1) {
            offset = 1;
            $("#less").attr("disabled", "disabled");
            $("#begin").attr("disabled", "disabled");
        } else {
            $("#less").removeAttr("disabled");
            $("#begin").removeAttr("disabled");
        }
        if (offset < 10 && $("#numberPage").val() > $("#totalNumberPages").text()) {
            $("#numberPage").val(1);
            $("#more").attr("disabled", "disabled");
            $("#last").attr("disabled", "disabled");
        }
        status = true;
    } else {
        offset = 1;
        if ((totalValues - offset) <= pageSize && ($("#numberPage").val() == $("#totalNumberPages").text())) {
            $("#more").attr("disabled", "disabled");
            $("#last").attr("disabled", "disabled");
        } else {
            $("#more").removeAttr("disabled");
            $("#last").removeAttr("disabled");
        }
        $("#less").attr("disabled", "disabled");
        $("#begin").attr("disabled", "disabled");
        $("#numberPage").val(1);
    }
    return status;
}

/**
 * Hide button back
 */
$("#back").toggle();
$("#totalResults").toggle();
$("#more").attr("disabled", "disabled");
$("#last").attr("disabled", "disabled");
$("#less").attr("disabled", "disabled");
$("#begin").attr("disabled", "disabled");
$(".pagination-section").toggle();
$("#test").hide();
$(".result").remove();

/**
 * Button back on click
 */
$("#back").click(function() {
    pageSize = 10;
    offset = 1;
    totalValues = 10;
    $("#searchPanel").show();
    $("#back").hide();
    $("#totalResults").hide();
    $(".pagination-section").hide();
    $(".result").remove();
});

$("#begin").click(function() {
    offset = 1;
    $("#numberPage").val("1");
    $(".result").remove();
    $(idForm).submit();
});

$("#more").click(function() {
    if (offset == 1) {
        offset = 10;
    } else {
        offset += 10;
    }
    $("#numberPage").val(parseInt($("#numberPage").val()) + 1);
    $(".result").remove();
    $(idForm).submit();
});

$("#less").click(function() {
    offset -= 10;
    if (offset < 1) {
        offset = 1
    }

    $("#numberPage").val(parseInt($("#numberPage").val()) - 1);
    $(".result").remove();
    $(idForm).submit();
});

$("#last").click(function() {
    offset = (totalValues - 10);
    $("#numberPage").val($("#totalNumberPages").text());
    $(".result").remove();
    $(idForm).submit();
});

$(function() {
    $("#skipPagination").submit(
            function() {
                var numberPage = $("#numberPage").val();
                if (numberPage <= 1)
                    offset = 1;
                else
                    offset = parseInt("" + (numberPage - 1) * 10);
                $(".result").remove();
                $(idForm).submit();
                return false;
            }
            );
});

function submitGeneIdentifier() {

}

/**
 * Add function to submit form
 */
$(function() {
    $("#formGeneIdentifier").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = searchGene($(this).serialize(), pageSize, offset).responseJSON;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#formGeneIdentifier", totalValues))
                    idForm = "#formGeneIdentifier";
                var gene = pagedResponse.response;
                if (gene.length > 0) {
                    contentGeneData(gene);
                } else {
                    $("#formGeneIdentifier").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }
                return false; 
            }
            );
});
$(function autommaticId() {
    if($("#id").val() != "") {
        $("input[name=geneID]").val($("#id").val());
        $(".errors").remove();
        var pagedResponse = searchGene($("#formGeneIdentifier").serialize(), pageSize, offset).responseJSON;
        totalValues = pagedResponse.total;
        if (!verifyPagedResponse(idForm, "#formGeneIdentifier", totalValues))
            idForm = "#formGeneIdentifier";
        var gene = pagedResponse.response;
        if (gene.length > 0) {
            contentGeneData(gene);
        } else {
            $("#formGeneIdentifier").append("<div class='alert alert-danger errors'>No results found</div>");
            $("#totalResults").hide();
        }
        return false;
    }
}) 


/**
 * Add function to submit form
 */
$(function() {
    $("#formGeneDescription").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = searchGene($(this).serialize(), pageSize, offset).responseJSON;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#formGeneDescription", totalValues))
                    idForm = "#formGeneDescription";
                var gene = pagedResponse.response;
                if (gene.length > 0) {
                    contentGeneData(gene);
                } else {
                    $("#formGeneDescription").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }
                return false;
            }
            );
});

/**
 * Add function to submit form
 */
$(function() {
    $("#formAnalysesProteinCodingGenes").submit(
            function() {
                $(".errors").remove();
                if(
                        ($.inArray("Interpro", $('#components').val()) == 0 && $('input[name=noIP]').prop("checked")) ||
                        ($.inArray("GO", $('#components').val()) == 0 && $('input[name=noGO]').prop("checked")) ||
                        ($.inArray("TCDB", $('#components').val()) == 0 && $('input[name=noTC]').prop("checked")) ||
                        ($.inArray("eggNOG", $('#components').val()) == 0 && $('input[name=noOrth]').prop("checked")) ||
                        ($.inArray("KEGG", $('#components').val()) == 0 && $('input[name=noKEGG]').prop("checked")) ||
                        ($.inArray("RPS-BLAST", $('#components').val()) == 0 && $('input[name=noRps]').prop("checked")) ||
                        ($.inArray("BLAST", $('#components').val()) == 0 && $('input[name=noBlast]').prop("checked")) 
                ) {
                    $("#formAnalysesProteinCodingGenes").append("<div class='alert alert-danger errors'>Wrong query: positive and negative results required simultaneously</div>"); 
                    return false;
                }
                $("input[name=blastID]").val($("input[name=blastID]").val().replace(/\s/g, "")); 
                $("input[name=rpsID]").val($("input[name=rpsID]").val().replace(/\s/g, "")); 
                $("input[name=koID]").val($("input[name=koID]").val().replace(/\s/g, "")); 
                $("input[name=orthID]").val($("input[name=orthID]").val().replace(/\s/g, "")); 
                $("input[name=tcdbID]").val($("input[name=tcdbID]").val().replace(/\s/g, "")); 
                $("input[name=goID]").val($("input[name=goID]").val().replace(/\s/g, ""));
                $("input[name=interproID]").val($("input[name=interproID]").val().replace(/\s/g, ""));
                var pagedResponse = analysesCDS($(this).serialize(), pageSize, offset).responseJSON;
                try {
                    var ids = pagedResponse.response;
                    totalValues = pagedResponse.total;
                    if (!verifyPagedResponse(idForm, "#formAnalysesProteinCodingGenes", totalValues))
                        idForm = "#formAnalysesProteinCodingGenes";
                    if (ids.length > 0) {
                        var featuresIDs = ids.join(" ");
                        var data = searchGeneByID(featuresIDs).responseJSON.response;
                        if (data.length > 0) {
                            contentGeneData(data);
                        } else {
                            $("#formAnalysesProteinCodingGenes").append("<div class='alert alert-danger errors'>Ooops, no gene found</div>");
                            $("#totalResults").hide();
                        }
                    } else {
                        $("#formAnalysesProteinCodingGenes").append("<div class='alert alert-danger errors'>Ooops, no gene found</div>");
                        $("#totalResults").hide();
                    }
                } catch(exception) {
                    $("#formAnalysesProteinCodingGenes").append("<div class='alert alert-danger errors'>Ooops, no gene found</div>");
                    $("#totalResults").hide();
                }
                return false;
            }
    );
});

/**
 * Add function to submit form
 */
$(function() {
    $("#trna-form").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = trnaSearch($(this).serialize(), pageSize, offset).responseJSON;
                var tRNAList = pagedResponse.response;
                totalValues = pagedResponse.total;
                if (tRNAList.length > 0) {
                    if (!verifyPagedResponse(idForm, "#trna-form", totalValues))
                        idForm = "#trna-form";
                    var featuresIDs = "";
                    for (i = 0; i < tRNAList.length; i++) {
                        featuresIDs += tRNAList[i].id + " ";
                    }
                    var data = searchGeneByID(featuresIDs).responseJSON.response;

                    if (data.length > 0) {
                        contentGeneData(data);
                    } else {
                        $("#trna-form").append("<div class='alert alert-danger errors'>Ooops, no gene found</div>");
                        $("#totalResults").hide();
                    }
                } else {
                    $("#trna-form").append("<div class='alert alert-danger errors'>Ooops, no gene found</div>");
                    $("#totalResults").hide();
                }
                return false;
            }
    );
});

$(function() {
    $("#rRNA-form").submit(function() {
        $(".errors").remove();
        var pagedResponse = searchrRNA($(this).serialize(), pageSize, offset).responseJSON;
        var rRNAList = pagedResponse.response;
        totalValues = pagedResponse.total;
        if(rRNAList.length > 0) {
            if (!verifyPagedResponse(idForm, "#rRNA-form", totalValues))
                idForm = "#rRNA-form";
            var featuresIDs = "";
            for (i = 0; i < rRNAList.length; i++) {
                featuresIDs += rRNAList[i] + " ";
            }
            var data = searchGeneByID(featuresIDs).responseJSON.response;
            if (data.length > 0) {
                contentGeneData(data);
            } else {
                $("#rRNA-form").append("<div class='alert alert-danger errors'>No results found</div>");
                $("#totalResults").hide();
            }
        } else {
            $("#rRNA-form").append("<div class='alert alert-danger errors'>No results found</div>");
            $("#totalResults").hide();
        }

        return false;
    });
});

/**
 * Add function to submit form
 */
$(function() {
    $("#tandemRepeats-form").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = tandemRepeatsSearch($(this).serialize(), pageSize, offset).responseJSON;
                var tandemRepeatsList = pagedResponse.response;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#tandemRepeats-form", totalValues))
                    idForm = "#tandemRepeats-form";
                if (tandemRepeatsList.length > 0) {
                    $("#searchPanel").hide();
                    $("#back").show();
                    var html = "<table class='table table-striped table-bordered table-hover result'>" +
                        "	<thead>" +
                        "		<tr>" +
                        "			<th>Contig</th>" +
                        "			<th>Start coordinate</th>" +
                        "			<th>End coordinate</th>" +
                        "			<th>Repeat length</th>" +
                        "			<th>Copy number</th>" +
                        "			<th>Repeat sequence</th>" +
                        "		</tr>" +
                        "	</thead>" +
                        "	<tbody>";
                    for (i = 0; i < tandemRepeatsList.length; i++) {
                        html += "		<tr>" +
                            "			<td>"+tandemRepeatsList[i].contig+" (<a href='"+window.location.pathname.replace("/SearchDatabase", "")+"/DownloadFileByContigAndType?contig=" + tandemRepeatsList[i].contig + "&type=trf' target='_blank'>result</a>)</td>" +
                            "			<td>" + tandemRepeatsList[i].start + "</td>" +
                            "			<td>" + tandemRepeatsList[i].end + "</td>" +
                            "			<td>" + tandemRepeatsList[i].length + "</td>" +
                            "			<td>" + tandemRepeatsList[i].copy_number + "</td>" +
                            "			<td>" + tandemRepeatsList[i].sequence + "</td>" +
                            "		</tr>";
                    }
                    html += "	</tbody>" +
                        "</table>";
                    $("#searchPanel").parent().append(html);
                    $(".pagination-section").show();
                } else {
                    $("#tandemRepeats-form").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }
                return false;
            }
    );
});

$(function() {
  $('select[name=type]').focus(
    function() {
      if ($('select[name=type] option').length <= 1) {
        ribosomal_rnas = getRibosomalRNAs().responseJSON.response;
        for (i = 0; i < ribosomal_rnas.length; i++) {
          $('select[name=type]').append($('<option>', {
            value: ribosomal_rnas[i],
            text: ribosomal_rnas[i]
          }));
        }
      }
      return false
    }
  );
});

$(function() {
  $('select[name=ncRNAtargetClass]').focus(
    function() {
      if ($('select[name=ncRNAtargetClass] option').length <= 1) {
        target_classes = getTargetClass().responseJSON.response;
        for (i = 0; i < target_classes.length; i++) {
          $('select[name=ncRNAtargetClass]').append($('<option>', {
            value: target_classes[i],
            text: target_classes[i]
          }));
        }
      }
      return false
    }
  );
});

/**
 * Add function to submit form
 */
$(function() {
    $("#otherNonCodingRNAs-form").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = ncRNASearch($(this).serialize(), pageSize, offset).responseJSON;
                var nonCodingRNAList = pagedResponse.response;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#otherNonCodingRNAs-form", totalValues))
                    idForm = "#otherNonCodingRNAs-form";
                if (nonCodingRNAList.length > 0) {
                    var featuresIDs = "";
                    for (i = 0; i < nonCodingRNAList.length; i++) {
                        featuresIDs += nonCodingRNAList[i].id + " ";
                    }
                    var data = searchGeneByID(featuresIDs).responseJSON.response;
                    if (data.length > 0) {
                        contentGeneData(data);
                    } else {
                        $("#otherNonCodingRNAs-form").append("<div class='alert alert-danger errors'>Ooops, no gene found</div>");
                        $("#totalResults").hide();
                    }
                } else {
                    $("#otherNonCodingRNAs-form").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }
                ;
                return false;
            }
    );
});

/**
 * Add function to submit form
 */
$(function() {
    $("#transcriptionalTerminators-form").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = transcriptionalTerminatorSearch($(this).serialize(), pageSize, offset).responseJSON;
                var transcriptionalTerminatorList = pagedResponse.response;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#transcriptionalTerminators-form", totalValues))
                    idForm = "#transcriptionalTerminators-form";
                if (transcriptionalTerminatorList.length > 0) {
                    $("#searchPanel").hide();
                    $("#back").show();
                    var html = "<table class='table table-striped table-bordered table-hover result'>" +
                        "	<thead>" +
                        "		<tr>" +
                        "			<th>Contig</th>" +
                        "			<th>Start coordinate</th>" +
                        "			<th>End coordinate</th>" +
                        "			<th>Confidence</th>" +
                        "			<th>Hairpin score</th>" +
                        "			<th>Tail score</th>" +
                        "		</tr>" +
                        "	</thead>" +
                        "	<tbody>";
                    for (i = 0; i < transcriptionalTerminatorList.length; i++) {
                        html += "		<tr>" +
                            "			<td>" + transcriptionalTerminatorList[i].contig + " (<a href='"+window.location.pathname.replace("/SearchDatabase", "")+"/DownloadFileByContigAndType?contig=" + transcriptionalTerminatorList[i].contig + "&type=transterm' target='_blank'>result</a>)</td>" +
                            "			<td>" + transcriptionalTerminatorList[i].start + "</td>" +
                            "			<td>" + transcriptionalTerminatorList[i].end + "</td>" +
                            "			<td>" + transcriptionalTerminatorList[i].confidence + "</td>" +
                            "			<td>" + transcriptionalTerminatorList[i].hairpin_score + "</td>" +
                            "			<td>" + transcriptionalTerminatorList[i].tail_score + "</td>" +
                            "		</tr>";
                    }
                    html += "	</tbody>" +
                        "</table>";
                    $("#searchPanel").parent().append(html);
                    $(".pagination-section").show();
                } else {
                    $("#transcriptionalTerminators-form").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }
                return false;
            }
    );
});

/**
 * Add function to submit form
 */
$(function() {
    $("#ribosomalBindingSites-form").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = rbsSearch($(this).serialize(), pageSize, offset).responseJSON;
                var rbsList = pagedResponse.response;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#ribosomalBindingSites-form", totalValues))
                    idForm = "#ribosomalBindingSites-form";
                if (rbsList.length > 0) {
                    $("#searchPanel").hide();
                    $("#back").show();
                    var html = "<table class='table table-striped table-bordered table-hover result'>" +
                        "	<thead>" +
                        "       <tr>"+
                        "           <th></th>"+
                        "           <th colspan='2'>Ribosomal binding sites</th>"+ 
                        "           <th colspan='2'>Old start</th>"+   
                        "       </tr>"+
                        "		<tr>" +
                        "			<th>Contig</th>" +
                        "			<th>Site position</th>" +
                        "			<th>Site pattern</th>" + 
                        "			<th>Codon</th>" + 
                        "			<th>Start Position</th>" + 
                        "			<th>New start codon</th>" +
                        "			<th>Position shift</th>" + 
                        "		</tr>" +
                        "	</thead>" +
                        "	<tbody>";
                    for (i = 0; i < rbsList.length; i++) {
                        html += "<tr>" +
                            "			<td>" + rbsList[i].contig + " (<a href='"+window.location.pathname.replace("/SearchDatabase", "")+"/DownloadFileByContigAndType?contig=" + rbsList[i].contig + "&type=rbsfinder' target='_blank'>result</a>)</td>" +
                            "   		<td>" + rbsList[i].end + "</td>" + 
                            "			<td>" + rbsList[i].site_pattern + "</td>" +
                            "           <td>" + rbsList[i].old_start + "</td>" +
                            "           <td>" + rbsList[i].old_position + "</td>  " +
                            "			<td>" + rbsList[i].new_start + "</td>";
                        if(rbsList[i].position_shift === undefined) {
                            html += "			<td>0</td>";
                        } else {
                            html += "			<td>" + rbsList[i].position_shift + "</td>";
                        }
                        html +=	"		</tr>";
                    }
                    html += "	</tbody>" +
                        "</table>";
                    $("#searchPanel").parent().append(html);
                    $(".pagination-section").show();
                } else {
                    $("#ribosomalBindingSites-form").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }
                return false;
            }
    );
});

$(function() {
    $("#geneByPosition").submit(
            function() {
                $(".errors").remove();
                if(idForm != "#geneByPosition") {
                    offset = 1;
                }
                var pagedResponse = getGeneByPosition($(this).serialize(), pageSize, offset).responseJSON;
                var list = pagedResponse.response;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#geneByPosition", totalValues))
                    idForm = "#geneByPosition";
                if(list.length > 0) {
                    $("#searchPanel").hide();
                    $("#back").show();
                    contentGeneData(list);
                } else {
                    $("#back").click();
                    $("#horizontalGeneTransfers-form").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }
                return false;	
            }
    );
});

/**
 * Add function to submit form
 */
$(function() {
    $("#horizontalGeneTransfers-form").submit(
            function() {
                $(".errors").remove();
                var pagedResponse = alienhunterSearch($(this).serialize(), pageSize, offset).responseJSON;
                var alienhunterList = pagedResponse.response;
                totalValues = pagedResponse.total;
                if (!verifyPagedResponse(idForm, "#horizontalGeneTransfers-form", totalValues))
                    idForm = "#horizontalGeneTransfers-form";
                if (alienhunterList.length > 0) {
                    $("#searchPanel").hide();
                    $("#back").show();
                    var html = "<table class='table table-striped table-bordered table-hover result'>" +
                        "	<thead>" +
                        "		<tr>" +
                        "			<th>Genes</th>" +
                        "			<th>Contig</th>" +
                        "			<th>Start coordinate</th>" +
                        "			<th>End coordinate</th>" +
                        "			<th>Score</th>" +
                        "			<th>Length</th>" +
                        "			<th>Threshold</th>" +
                        "		</tr>" +
                        "	</thead>" +
                        "	<tbody>";
                    for (var i = 0; i < alienhunterList.length; i++) {
                        html += "		<tr>" +
                            "			<td><button id='horizontal-transference-" + alienhunterList[i].id+"' type='button' class='btn btn-info btn-md'>Genes</button></td>" +
                            "			<td>" + alienhunterList[i].contig + " (<a href='"+window.location.pathname.replace("/SearchDatabase", "")+"/DownloadFileByContigAndType?contig=" + alienhunterList[i].contig + "&type=alienhunter' target='_blank'>result</a>)</td>" +
                            "			<td>" + alienhunterList[i].start + "</td>" +
                            "			<td>" + alienhunterList[i].end + "</td>" +
                            "			<td>" + alienhunterList[i].score + "</td>" +
                            "			<td>" + alienhunterList[i].length + "</td>" +
                            "			<td>" + alienhunterList[i].threshold + "</td>" +
                            "		</tr>";
                    }
                    html += "	</tbody>" +
                        "</table>";
                    $("#searchPanel").parent().append(html);
                    $(".pagination-section").show();
                    var contig = "";
                    var start = 0;
                    var end = 0;
                    for (var i = 0; i < alienhunterList.length; i++) {
                        contig = alienhunterList[i].contig;
                        start = alienhunterList[i].start;
                        end = alienhunterList[i].end;
                        $("#horizontal-transference-" + alienhunterList[i].id).click((function(contig, start, end) {
                            return function() {
                                $(".result").remove();
                                $("#contigGenePosition").val(contig);
                                $("#start").val(start);
                                $("#end").val(end);
                                $(".result").remove();
                                $("#geneByPosition").submit();
                                return false;
                            }
                        })(contig, start, end));
                    }
                    contig = "";
                    start = 0;
                    end = 0;
                } else {
                    $("#horizontalGeneTransfers-form").append("<div class='alert alert-danger errors'>No results found</div>");
                    $("#totalResults").hide();
                }

                return false;
            }
    );
});

/**
 * Method used to deal with content of gene
 * 
 * @param data
 * @returns
 */
function contentGeneData(data) {
    for (var i = 0; i < data.length; i++) {
        var feature = data[i];
        var htmlContent = getHTMLContent("search-database/gene.tt").responseJSON.response;
        htmlContent = htmlContent.replace(/(\[\% result.feature_id \%\])+/gim, feature.feature_id);
        htmlContent = htmlContent.replace(/(\[\% result.name \%\])/gim, feature.name);
        htmlContent = htmlContent.replace(/(\[\% result.uniquename \%\])/gim, feature.uniquename);
        $("#searchPanel").hide();
        $("#back").show();
        $(".pagination-section").show();
        $("#searchPanel").parent().append(htmlContent);

        $("#result-panel-title-" + feature.feature_id).on("click", function() {
            var href = $(this).attr('href');
            var name = $(this).text().substring(0, $(this).text().indexOf("-") - 1);
            var product = $(this).text().substring($(this).text().indexOf("-") + 1, $(this).text().length);
            var data = getGeneBasics(href.replace("#", "")).responseJSON.response;

            dealDataResults(href, name, data, product);

            return false;
        });
    }
}

/**
 * Method used to deal with data results and standard visualization, need to
 * modularize
 * 
 * @param href
 *            panel of results
 * @param featureName
 * @param data
 * @returns
 */
function dealDataResults(href, featureName, data, product) {
    if ($(href).is(":hidden")) {
        data = data[0];
        var htmlContent = getHTMLContent("search-database/geneBasics.tt").responseJSON.response;
        htmlContent = htmlContent.replace("[% result.type %]", data.predictor);
        htmlContent = htmlContent.replace("[% result.uniquename %]", data.uniquename);
        htmlContent = htmlContent.replace("[% result.fstart %]", data.fstart);
        htmlContent = htmlContent.replace("[% result.fend %]", data.fend);
        htmlContent = htmlContent.replace("[% result.length %]", (data.fend - data.fstart + 1));
        var type = data.type;
        var name = data.uniquename;
        var subsequence = getSubsequence(type, featureName, name, data.fstart, data.fend).responseJSON.response;
        var htmlSequence = getHTMLContent("search-database/sequence.tt").responseJSON.response;
        htmlSequence = htmlSequence.replace("[% result.pathname %]", window.location.pathname.replace("/SearchDatabase", ""));
        htmlSequence = htmlSequence.replace("[% result.contig %]", data.uniquename);
        htmlSequence = htmlSequence.replace("[% result.start %]", data.fstart );
        htmlSequence = htmlSequence.replace("[% result.end %]", data.fend );
        htmlSequence = htmlSequence.replace("[% result.reverseComplement %]", 0); 
        htmlSequence = htmlSequence.replace("[% result.feature_id %]", href.replace("#", ""));
        htmlSequence = htmlSequence.replace("[% result.feature_id %]", href.replace("#", ""));
        htmlSequence = htmlSequence.replace("[% result.sequence %]", subsequence.sequence);
        if (type == "CDS") {
            htmlContent += htmlSequence;
            var subevidences = new Array();
            subevidences = getSubEvidences(href.replace("#", ""), featureName).responseJSON.response;
            //subevidences = subevidences.sort(function(a,b){
            //    var x = a.type.toLowerCase();
            //    var y = b.type.toLowerCase();
            //    return x > y ? -1 : x < y ? 1 : 0;
            //});
            subevidences = subevidences.sort(function(a,b){
                var x = a.program_description.toLowerCase();
                var y = b.program_description.toLowerCase();
                return x < y ? -1 : x > y ? 1 : 0;
            });
            var components = new Object();
            var componentsEvidences = new Array();
            var counterComponentsEvidences = 0;
            for (var i = 0; i < subevidences.length; i++) {
                var componentName = subevidences[i].program.replace(".pl", "");

                if ($.inArray(componentName, componentsEvidences) == -1) {
                    var htmlEvidence = getHTMLContent("search-database/evidences.tt").responseJSON.response;
                    htmlEvidence = htmlEvidence.replace("[% result.componentName %]", componentName);
                    htmlEvidence = htmlEvidence.replace("[% result.id %]", href.replace("#", ""));
                    if (subevidences[i].type == 'intervals') {
                        if(subevidences[i].program == "annotation_go.pl") {
                            var fuckingTitle = subevidences[i].program_description;
                            if(subevidences[i].is_obsolete[0] == undefined)
                                fuckingTitle = "<a>" + fuckingTitle + " - No results found</a>";
                            else
                                fuckingTitle = "<a href='#evidence-annotation_go-"+href.replace("#", "")+"' data-toggle='collapse' data-parent='#accordion' >" + fuckingTitle + "</a>";
                            htmlEvidence = "<div class='panel panel-default'>"+
                                    "<div class='panel-heading'>"+
                                    "    <div class='panel-title'>" +
                                    "         <div class='row'><div class='col-md-12'>" + fuckingTitle + "</div></div>"+
                                    "    </div>"+
                                    "</div>"+
                                    "<div id='evidence-annotation_go-"+href.replace("#", "")+"' class='panel-body collapse'>";
                            var biologicalProcess = "<div class='panel panel-default'><div class='panel-heading'><div class='panel-title'>Biological process</div></div><div class='panel-body'><div class='notice-board'><ul>";
                            var molecularFunction = "<div class='panel panel-default'><div class='panel-heading'><div class='panel-title'>Molecular function</div></div><div class='panel-body'><div class='notice-board'><ul>";
                            var celularComponent = "<div class='panel panel-default'><div class='panel-heading'><div class='panel-title'>Celular component</div></div><div class='panel-body'><div class='notice-board'><ul>";
                            for (var j = 0; j < subevidences[i].is_obsolete.length; j++) {
                                for (var k = 0; k < subevidences[i].is_obsolete[j].length; k++) {
                                    var evidences = ""; 
				    if(subevidences[i].is_obsolete[j][k].includes('Biological Process')) {
					evidences = subevidences[i].is_obsolete[j][k].split("Biological Process: ");
				    } else if(subevidences[i].is_obsolete[j][k].includes('Molecular Function')) {
					evidences = subevidences[i].is_obsolete[j][k].split("Molecular Function: ");
				    } else if(subevidences[i].is_obsolete[j][k].includes('Cellular Component')) {
					evidences = subevidences[i].is_obsolete[j][k].split("Cellular Component: ");
  				    }
				    
				    for(var l = 0; l < evidences.length; l++) {
					if(evidences[l] != "") {
                                    	    var regexGO = /(GO:\d+)/g;
					    var evidence = evidences[l];
                                            var process = regexGO.exec(evidence);
					    if(process != null) {
                                                evidence = evidence.replace(process[0], "<a style='color: rgb(35, 82, 124);' target='_blank' href='http://www.ebi.ac.uk/QuickGO/GTerm?id="+process[0]+"'>"+process[0]+"</a>");
					    }
                                            if(subevidences[i].is_obsolete[j][k].includes('Biological Process') && !biologicalProcess.includes(process[0]) ) {
                                                biologicalProcess+= "<li>" + evidence + "</li>";
                                            } else if(subevidences[i].is_obsolete[j][k].includes('Molecular Function') && !molecularFunction.includes(process[0])) {
                                                molecularFunction+= "<li>" + evidence + "</li>";
                                            } else if(subevidences[i].is_obsolete[j][k].includes('Cellular Component') && !celularComponent.includes(process[0])) {
                                                celularComponent+= "<li>" + evidence + "</li>";
                                            }
					}
                                    }
                                }
                            }
                            var caralho = /li/g;
                            if (caralho.exec(biologicalProcess) == undefined || caralho.exec(biologicalProcess) == null ) {
                                biologicalProcess += "<li>No terms found</li>";
                            } 
			    caralho = /li/g;
	
			    if (caralho.exec(molecularFunction) == undefined || caralho.exec(molecularFunction) == null) { 
                                molecularFunction += "<li>No terms found</li>";
                            } 
			    caralho = /li/g;
			    if (caralho.exec(celularComponent) == undefined || caralho.exec(celularComponent) == null) { 
                                celularComponent += "<li>No terms found</li>";
                            }

                            biologicalProcess += "</ul></div></div></div>";
                            molecularFunction += "</ul></div></div></div>";
                            celularComponent += "</ul></div></div></div>";
                            htmlEvidence += biologicalProcess + molecularFunction + celularComponent+ "</div></div></div>"; 
                        } else {
                            htmlEvidence = htmlEvidence.replace("[% result.descriptionComponent %]", "<div class='row'><div class='col-md-11'><a style='color: inherit;' id='anchor-evidence-" + componentName + "-" + href.replace("#", "") + "' data-toggle='collapse' data-parent='#accordion' href='#evidence-" + componentName + "-" + href.replace("#", "") + "'>" + subevidences[i].program_description + "</a></div><div class='col-md-1'><a href='" + window.location.pathname.replace("/SearchDatabase", "") + "/ViewResultByComponentID?locus_tag=" + featureName + "&name="+componentName+"' target='_blank'>View</a></div></div>");
                        }
                    } else if(subevidences[i].type == 'similarity') {
                        htmlEvidence = htmlEvidence.replace("[% result.descriptionComponent %]", "<a id='anchor-evidence-" + componentName + "-" + href.replace("#", "") + "' data-toggle='collapse' data-parent='#accordion' href='#evidence-" + componentName + "-" + href.replace("#", "") + "'>" + subevidences[i].program_description + "</a>");
                    } else {
                        if(componentName == 'annotation_tcdb') {
                            htmlEvidence = htmlEvidence.replace("[% result.descriptionComponent %]", "<div class='row'><div class='col-md-11'>" + subevidences[i].program_description + " - No results found</div></div>");
                        } else {
                            htmlEvidence = htmlEvidence.replace("[% result.descriptionComponent %]", "<div class='row'><div class='col-md-11'>" + subevidences[i].program_description + " - No results found</div><div class='col-md-1'><a href='" + window.location.pathname.replace("/SearchDatabase", "") + "/ViewResultByComponentID?locus_tag=" + featureName + "&name="+componentName+"' target='_blank'>View</a></div></div>");
                        }
                    }
                    htmlContent += htmlEvidence;
                    componentsEvidences[counterComponentsEvidences] = componentName;
                    counterComponentsEvidences++;
                }

                if (typeof components[componentName] == 'undefined') {
                    components[componentName] = new Array();
                }
                var arrayEvidences = components[componentName];
                if(componentName == "annotation_tmhmm") {
                    arrayEvidences[components[componentName].length] = {
                        "id" : subevidences[i].id,
                        "type" : subevidences[i].type,
                        "start" : subevidences[i].start,
                        "end" :	subevidences[i].end
                    };
                } else {
                    arrayEvidences[components[componentName].length] = {
                        "id" : subevidences[i].id,
                        "type" : subevidences[i].type
                    };
                }

                components[componentName] = arrayEvidences;
            }

            addPanelResult(href, htmlContent);

            for (var component in components) {
                console.log(component);
                if(components[component].id != "") {
                    $("#anchor-evidence-" + component + "-" + href.replace("#", "")).click(function clickEvidences() {
                        var componentTemp = this.id.replace("anchor-evidence-", "");
                        componentTemp = componentTemp.replace("-" + href.replace("#", ""), "");
                        console.log(componentTemp);
                        if ($("#evidence-" + componentTemp + "-" + href.replace("#", "")).is(":hidden")) {
                            $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                            for (i = 0; i < components[componentTemp].length; i++) {
                                var response = undefined;
                                if (componentTemp != "annotation_phobius" && componentTemp != "annotation_tmhmm" && componentTemp != 'annotation_orthology' && componentTemp != 'annotation_pathways'
                                        && componentTemp != 'annotation_interpro' && componentTemp != 'annotation_predgpi' && componentTemp != 'annotation_dgpi' && componentTemp != "annotation_tcdb" && componentTemp != "annotation_signalP") {
                                    response = getSimilarityEvidenceProperties(components[componentTemp][i].id, componentTemp).responseJSON.response;
                                    var htmlSubevidence = getHTMLContent("search-database/subEvidences.tt").responseJSON.response;
                                    htmlSubevidence = htmlSubevidence.replace("[% result.feature_id %]", components[componentTemp][i].id);
                                    htmlSubevidence = htmlSubevidence.replace("[% result.feature_id %]", "<div class='row'><div class='col-md-11'>" + response.identifier + " - " + response.description + "</div><div class='col-md-1'><a href='"+ window.location.pathname.replace("/SearchDatabase", "") +"/ViewResultByComponentID?locus_tag=" + featureName + "&name=" + componentTemp +  "' target='_blank'>View</a></div></div>");

                                    htmlSubevidence = htmlSubevidence.replace("[% result.feature_id %]", components[componentTemp][i].id);
                                    addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), htmlSubevidence);
                                }
                                if (components[componentTemp][i].type == "similarity") {
                                    var html = "";
                                    //								if(componentTemp == "annotation_blast" || componentTemp == "annotation_rpsblast") {
                                    html = getHTMLContent("search-database/similarityBasicResult.tt").responseJSON.response;
                                    if (componentTemp == "annotation_blast") {
                                        html = html.replace("[% result.identifier %]", "<a href='http://www.ncbi.nlm.nih.gov/protein/" + response.identifier + "' target='_blank' >" + response.identifier + "</a>");
                                    } else if (componentTemp == "annotation_rpsblast") {
                                        html = html.replace("[% result.identifier %]", "<a href='http://www.ncbi.nlm.nih.gov/Structure/cdd/cddsrv.cgi?uid=" + response.identifier + "' target='_blank' >" + response.identifier + "</a>");
                                    } else if (componentTemp == "annotation_hmmer") {
                                        html = html.replace("[% result.identifier %]", response.identifier);
                                    }
                                    html = html.replace("[% result.description %]", response.description);
                                    html = html.replace("[% result.evalue %]", response.evalue);
                                    html = html.replace("[% result.percent_id %]", response.percent_id);
                                    html = html.replace("[% result.similarity %]", response.similarity);
                                    html = html.replace("[% result.score %]", response.score);
                                    html = html.replace("[% result.block_size %]", response.block_size);
                                    //								} 
                                    addPanelResult("#subevidence-" + response.id, html);
                                    console.log(response);

                                } else if (components[componentTemp][i].type == "intervals") {
                                    var responseIntervals = getIntervalEvidenceProperties(components[componentTemp][i].id, componentTemp).responseJSON.response;
                                    var listHTMLs = new Array();
                                    var counterHTMLs = 0;
                                    var idTable = "";
                                    var architecture = "";
                                    var counterTMHMM = 0;
                                    if ($("#counterTMHMM").val() >= components[componentTemp].length) {
                                        counterTMHMM = 0;
                                    } else if ($("#counterTMHMM").val() != undefined) {
                                        counterTMHMM = $("#counterTMHMM").val();
                                    }

                                    //								 ||
                                    //									$("#counterTMHMM").val() >= components[componentTemp].length
                                    if ($("#tableArchitectureTMHMM-"+href.replace("#", "")) == undefined ||
                                            $("#counterTMHMM").val() == undefined) {
                                        addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), "<table class='table table-striped table-hover'>" +
                                                "	<thead><tr><th>Direction</th><th>Start</th><th>End</th></tr></thead>" +
                                                "	<tbody id='tableArchitectureTMHMM-"+href.replace("#", "")+"' class='architecture-tmhmm' class='collapsed'>" +
                                                "	</tbody>" +
                                                "</table>");
                                    } else {
                                        architecture = $("#tableArchitectureTMHMM-"+href.replace("#", "")).html();
                                    }

                                    if (componentTemp == 'annotation_interpro') {
                                        for (var j = 0; j < responseIntervals.properties.length; j++) {
                                            $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                            html = getHTMLContent("search-database/interproBasicResult.tt").responseJSON.response;
                                            html = html.replace("[% result.componentName %]", componentTemp);
                                            html = html.replace("[% result.componentName %]", componentTemp);
                                            html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                            html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                            html = html.replace("[% result.counter %]", counterHTMLs);
                                            html = html.replace("[% result.counter %]", responseIntervals.properties[j].interpro_id + ' - ' + responseIntervals.properties[j].description_interpro);
                                            html = html.replace("[% result.counter %]", counterHTMLs);
                                            html = html.replace("[% result.interpro_id %]", responseIntervals.properties[j].interpro_id);
                                            html = html.replace("[% result.interpro_id %]", responseIntervals.properties[j].interpro_id);
                                            html = html.replace("[% result.interpro_id %]", responseIntervals.properties[j].interpro_id);
                                            html = html.replace("[% result.description_interpro %]", responseIntervals.properties[j].description_interpro);
                                            html = html.replace("[% result.description_interpro %]", responseIntervals.properties[j].description_interpro);
                                            html = html.replace("[% result.DB_id %]", responseIntervals.properties[j].DB_id);
                                            html = html.replace("[% result.DB_id %]", responseIntervals.properties[j].DB_id);
                                            html = html.replace("[% result.DB_name %]", responseIntervals.properties[j].DB_name);
                                            html = html.replace("[% result.description %]", responseIntervals.properties[j].description);
                                            var regexGO = /(GO:\d+)/g;
                                            if (responseIntervals.properties[j].evidence_process != undefined) {
                                                var evidenceProcess = responseIntervals.properties[j].evidence_process;
                                                var process = regexGO.exec(evidenceProcess);
                                                evidenceProcess = evidenceProcess.replace(process[0], "<a href='http://www.ebi.ac.uk/QuickGO/GTerm?id="+process[0]+"'>"+process[0]+"</a>");
                                                html = html.replace("[% result.evidence_process %]", evidenceProcess);
                                            } else {
                                                html = html.replace("[% result.evidence_process %]", responseIntervals.properties[j].evidence_process);
                                            }
                                            var regexGO = /(GO:\d+)/g;

                                            if (responseIntervals.properties[j].evidence_function != undefined) {
                                                var evidence = responseIntervals.properties[j].evidence_function;
                                                var process2 = regexGO.exec(responseIntervals.properties[j].evidence_function);
                                                evidence= evidence.replace(process2[0], "<a href='http://www.ebi.ac.uk/QuickGO/GTerm?id="+process2[0]+"'>"+process2[0]+"</a>");
                                                html = html.replace("[% result.evidence_function %]", evidence);
                                            } else {
                                                html = html.replace("[% result.evidence_function %]", responseIntervals.properties[j].evidence_function);
                                            }
                                            var regexGO = /(GO:\d+)/g;

                                            if (responseIntervals.properties[j].evidence_component != undefined) {
                                                var evidence= responseIntervals.properties[j].evidence_component;
                                                var process = regexGO.exec(evidence);
                                                evidence= evidence.replace(process[0], "<a href='http://www.ebi.ac.uk/QuickGO/GTerm?id="+process[0]+"'>"+process[0]+"</a>");
                                                html = html.replace("[% result.evidence_component %]", evidence);
                                            } else {
                                                html = html.replace("[% result.evidence_component %]", responseIntervals.properties[j].evidence_component);
                                            }
                                            html = html.replace("[% result.score %]", responseIntervals.properties[j].score);
                                            listHTMLs[counterHTMLs] = html;
                                            counterHTMLs++;
                                        }
                                        idTable = "#evidence-" + componentTemp + "-" + href.replace("#", "");
                                    } else if (componentTemp == 'annotation_tmhmm') {
                                        idTable = "#evidence-" + componentTemp + "-" + href.replace("#", "");
                                        for (var j = 0; j < responseIntervals.properties.length; j++) {
                                            //										$("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                            counterTMHMM++;
                                            if($("#predicted-"+href.replace("#", "")).text() == "") {
                                                listHTMLs[counterHTMLs] = "<div id='predicted-"+href.replace("#", "")+"' class='row architecture-tmhmm'><div class='col-md-3'><p>Predicted Transmembrane domains</p></div><div class='col-md-9'>" + responseIntervals.properties[j].predicted_TMHs + "</div></div>";
                                                counterHTMLs++;
                                            }
                                            if (responseIntervals.properties[j].direction == "inside") {
                                                $("#tableArchitectureTMHMM-"+href.replace("#", "")).append("<tr><td>Inside the cytoplasm</td><td>"+components[componentTemp][i].start+"</td><td>"+components[componentTemp][i].end+"</td></tr>");
                                            } else if (responseIntervals.properties[j].direction == "outside") {
                                                $("#tableArchitectureTMHMM-"+href.replace("#", "")).append("<tr><td>Outside the cytoplasm</td><td>"+components[componentTemp][i].start+"</td><td>"+components[componentTemp][i].end+"</td></tr>");
                                            } else if (responseIntervals.properties[j].direction == "TMhelix") {
                                                $("#tableArchitectureTMHMM-"+href.replace("#", "")).append("<tr><td>Transmembrane helix</td><td>"+components[componentTemp][i].start+"</td><td>"+components[componentTemp][i].end+"</td></tr>");
                                            }

                                            //										if($("#architecture-tmhmm").text() == "" ||
                                            //												$("#architecture-tmhmm").text() == undefined ||
                                            //												$("#counterTMHMM").val() >= components[componentTemp].length) {
                                            //											architecture += "	</tbody>" +
                                            //															"</table>";
                                            //										}										

                                            //										listHTMLs[counterHTMLs] = "<div class='row architecture-tmhmm'><div class='col-md-3'><p>Architecture:</p></div><div class='col-md-9'><p id='architecture-tmhmm'>" + architecture + "</p></div></div>";
                                            //listHTMLs[counterHTMLs] = "<div class='row architecture-tmhmm'><div class='col-md-12'>"+architecture+"</div></div>";
                                            //counterHTMLs++;


                                            listHTMLs[counterHTMLs] = "<input type='hidden' class='architecture-tmhmm' id='counterTMHMM' value='" + counterTMHMM + "' \>";
                                            counterHTMLs++;
                                        }
                                    } else if (componentTemp == 'annotation_tcdb') {
                                        for (var j = 0; j < responseIntervals.properties.length; j++) {
                                            $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                            html = getHTMLContent("search-database/tcdbBasicResult.tt").responseJSON.response;
                                            html = html.replace("[% result.componentName %]", componentTemp);
                                            html = html.replace("[% result.componentName %]", componentTemp);
                                            html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                            html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                            html = html.replace("[% result.counter %]", counterHTMLs);
                                            html = html.replace("[% result.counter %]", responseIntervals.properties[j].hit_description);
                                            html = html.replace("[% result.counter %]", counterHTMLs);
                                            html = html.replace("[% result.TCDB_ID %]", responseIntervals.properties[j].TCDB_ID);
                                            html = html.replace("[% result.TCDB_ID %]", responseIntervals.properties[j].TCDB_ID);
                                            html = html.replace("[% result.hit_description %]", responseIntervals.properties[j].hit_description);
                                            html = html.replace("[% result.TCDB_class %]", responseIntervals.properties[j].TCDB_class);
                                            html = html.replace("[% result.TCDB_subclass %]", responseIntervals.properties[j].TCDB_subclass);
                                            html = html.replace("[% result.TCDB_family %]", responseIntervals.properties[j].TCDB_family);
                                            html = html.replace("[% result.hit_name %]", responseIntervals.properties[j].hit_name);
                                            html = html.replace("[% result.hit_name %]", responseIntervals.properties[j].hit_name);
                                            html = html.replace("[% result.evalue %]", responseIntervals.properties[j].evalue);
                                            html = html.replace("[% result.percent_id %]", responseIntervals.properties[j].percent_id);
                                            html = html.replace("[% result.similarity %]", responseIntervals.properties[j].similarity);
                                            listHTMLs[counterHTMLs] = html;
                                            counterHTMLs++;
                                        }
                                        idTable = "#evidence-" + componentTemp + "-" + href.replace("#", "");
                                    } else if (componentTemp == 'annotation_pathways') {
                                        for (var j = 0; j < responseIntervals.properties.length; j++) {
                                            $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                            html = getHTMLContent("search-database/pathwaysBasicResult.tt").responseJSON.response;
                                            html = html.replace("[% result.orthologous_group_id %]", responseIntervals.properties[j].orthologous_group_id);
                                            html = html.replace("[% result.orthologous_group_id %]", responseIntervals.properties[j].orthologous_group_id);
                                            html = html.replace("[% result.orthologous_group_id %]", responseIntervals.properties[j].orthologous_group_id);
                                            html = html.replace("[% result.orthologous_group_description %]", responseIntervals.properties[j].orthologous_group_description);

                                            if(responseIntervals.pathways.length > 0) {
                                                html += "<div class='row'>"+
                                                    "<div class='col-md-12'>"+
                                                    "	<div class='table-responsive'>"+
                                                    "		<table class='table table-striped table-hover'>"+
                                                    "			<thead>"+
                                                    "				<tr>"+
                                                    "					<th>Pathways:</th>"+
                                                    "					<th>View map:</th>"+
                                                    "				</tr>"+	
                                                    "			</thead>"+
                                                    "			<tbody id='pathways-[% result.orthologous_group_id %]'>"+					
                                                    "			</tbody>"+
                                                    "		</table>"+
                                                    "	</div>"+
                                                    "</div>"+
                                                    "</div>"; 
                                                html = html.replace("[% result.orthologous_group_id %]", responseIntervals.properties[j].orthologous_group_id);
                                            }
                                            addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), html);

                                            if(responseIntervals.pathways.length > 0) {
                                                for (var pathway in responseIntervals.pathways) {
                                                    var htmlPathway = getHTMLContent("search-database/pathways.tt").responseJSON.response;
                                                    htmlPathway = htmlPathway.replace("[% result.metabolic_pathway_id %]", responseIntervals.pathways[pathway].id);
                                                    htmlPathway = htmlPathway.replace("[% result.metabolic_pathway_id %]", responseIntervals.pathways[pathway].id);
                                                    htmlPathway = htmlPathway.replace("[% result.metabolic_pathway_description %]", responseIntervals.pathways[pathway].description);
                                                    htmlPathway = htmlPathway.replace("[% result.viewmap %]", "<a href='reports/"+$("#report_pathways").val() + "/pathway_figures/" + responseIntervals.properties[j].orthologous_group_id +"-"+responseIntervals.pathways[pathway].id+".html' target='_blank'>Link</a>");
                                                    listHTMLs[counterHTMLs] = htmlPathway;
                                                    counterHTMLs++;
                                                }
                                            }										idTable = "#pathways-" + responseIntervals.properties[j].orthologous_group_id;
                                        }
                                    } else if (componentTemp == 'annotation_orthology') {
                                        for (var j = 0; j < responseIntervals.properties.length; j++) {
                                            $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                            html = getHTMLContent("search-database/orthologyBasicResult.tt").responseJSON.response;
                                            html = html.replace("[% result.orthologous_hit %]", responseIntervals.properties[j].orthologous_hit);
                                            html = html.replace("[% result.id %]", responseIntervals.id);
                                            addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), html);
                                            for (var orthology in responseIntervals.orthologous_groups) {
                                                var htmlOrthology = getHTMLContent("search-database/orthologies.tt").responseJSON.response;
                                                htmlOrthology = htmlOrthology.replace("[% result.orthologous_group %]", responseIntervals.orthologous_groups[orthology].group);
                                                htmlOrthology = htmlOrthology.replace("[% result.orthologous_group %]", responseIntervals.orthologous_groups[orthology].group);
                                                htmlOrthology = htmlOrthology.replace("[% result.orthologous_group_description %]", responseIntervals.orthologous_groups[orthology].description);
                                                listHTMLs[counterHTMLs] = htmlOrthology;
                                                counterHTMLs++;
                                            }
                                            idTable = "#orthology-" + responseIntervals.id;
                                        }
                                    } else if (componentTemp == 'annotation_predgpi') {
                                        $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                        if (typeof (responseIntervals.properties[0].result) === 'undefined') {
                                            for (var j = 0; j < responseIntervals.properties.length; j++) {
                                                html = getHTMLContent("search-database/predgpiBasicResult.tt").responseJSON.response;
                                                html = html.replace("[% result.componentName %]", componentTemp);
                                                html = html.replace("[% result.componentName %]", componentTemp);
                                                html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                                html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                                html = html.replace("[% result.counter %]", counterHTMLs);
                                                html = html.replace("[% result.counter %]", responseIntervals.properties[j].name);
                                                html = html.replace("[% result.counter %]", counterHTMLs);
                                                html = html.replace("[% result.name %]", responseIntervals.properties[j].name);
                                                html = html.replace("[% result.position %]", responseIntervals.properties[j].position);
                                                html = html.replace("[% result.specificity %]", responseIntervals.properties[j].specificity);
                                                html = html.replace("[% result.sequence %]", responseIntervals.properties[j].sequence);
                                                html = html.replace("[% result.start %]", responseIntervals.properties[j].fstart);
                                                html = html.replace("[% result.end %]", responseIntervals.properties[j].fend);
                                                html = html.replace("[% result.strand %]", (responseIntervals.properties[j].fstart >responseIntervals.properties[j].fend ) ? -1 : 1);
                                                listHTMLs[counterHTMLs] = html;
                                                counterHTMLs++;
                                            }
                                            idTable = "#evidence-" + componentTemp + "-" + href.replace("#", "");
                                        } else {
                                            html = getHTMLContent("search-database/dgpiNoResult.tt").responseJSON.response;
                                            html = html.replace("[% result.result %]", responseIntervals.properties[0].result);
                                            addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), html);
                                        }
                                    } else if (componentTemp == 'annotation_dgpi') {
                                        $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                        if (typeof (responseIntervals.properties[0].result) === 'undefined') {
                                            for (var j = 0; j < responseIntervals.properties.length; j++) {
                                                html = getHTMLContent("search-database/dgpiBasicResult.tt").responseJSON.response;
                                                html = html.replace("[% result.componentName %]", componentTemp);
                                                html = html.replace("[% result.componentName %]", componentTemp);
                                                html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                                html = html.replace("[% result.feature_id %]", href.replace("#", ""));
                                                html = html.replace("[% result.counter %]", counterHTMLs);
                                                html = html.replace("[% result.counter %]", counterHTMLs);
                                                html = html.replace("[% result.counter %]", counterHTMLs);
                                                html = html.replace("[% result.cleavage_site %]", responseIntervals.properties[j].cleavage_site);
                                                html = html.replace("[% result.score %]", responseIntervals.properties[j].score);
                                                html = html.replace("[% result.start %]", responseIntervals.properties[j].start);
                                                html = html.replace("[% result.end %]", responseIntervals.properties[j].end);
                                                html = html.replace("[% result.strand %]", responseIntervals.properties[j].strand);
                                                listHTMLs[counterHTMLs] = html;
                                                counterHTMLs++;
                                            }
                                            idTable = "#evidence-" + componentTemp + "-" + href.replace("#", "");
                                        } else {
                                            html = getHTMLContent("search-database/dgpiNoResult.tt").responseJSON.response;
                                            html = html.replace("[% result.result %]", responseIntervals.properties[0].result);
                                            addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), html);
                                        }
                                    } else if (componentTemp == 'annotation_bigpi') {
                                        $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                        if (typeof (responseIntervals.properties[0].result) === 'undefined') {
                                            for (var j = 0; j < responseIntervals.properties.length; j++) {
                                                html = getHTMLContent("search-database/bigpiBasicResult.tt").responseJSON.response;
                                                html = html.replace("[% result.counter %]", responseIntervals.properties[j].p_value);
                                                html = html.replace("[% result.counter %]", counterHTMLs);
                                                html = html.replace("[% result.pvalue %]", responseIntervals.properties[j].p_value);
                                                html = html.replace("[% result.position %]", responseIntervals.properties[j].position);
                                                html = html.replace("[% result.start %]", responseIntervals.properties[j].fstart);
                                                html = html.replace("[% result.end %]", responseIntervals.properties[j].fend);
                                                html = html.replace("[% result.strand %]", (responseIntervals.properties[j].fstart >responseIntervals.properties[j].fend ) ? -1 : 1);
                                                html = html.replace("[% result.score %]", responseIntervals.properties[j].score);
                                                listHTMLs[counterHTMLs] = html;
                                                counterHTMLs++;
                                            }
                                            idTable = "#evidence-" + componentTemp + "-" + href.replace("#", "");
                                        } else {
                                            html = getHTMLContent("search-database/dgpiNoResult.tt").responseJSON.response;
                                            html = html.replace("[% result.result %]", responseIntervals.properties[0].result);
                                            addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), html);
                                        }
                                    } else if (componentTemp == 'annotation_signalP') {
                                        for (var j = 0; j < responseIntervals.properties.length; j++) {
                                            $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                            html = getHTMLContent("search-database/signalPBasicResult.tt").responseJSON.response;
                                            html = html.replace("[% result.start_residue %]", responseIntervals.properties[j].start_residue);
                                            html = html.replace("[% result.end_residue %]", responseIntervals.properties[j].end_residue);
                                            html = html.replace("[% result.pep_sig %]", responseIntervals.properties[j].pep_sig);
                                            html = html.replace("[% result.cutoff %]", responseIntervals.properties[j].cutoff);
                                            html = html.replace("[% result.score %]", responseIntervals.properties[j].score);
                                            addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), html);
                                        }
                                    } else if (componentTemp == 'annotation_phobius') {
                                        $("#evidence-" + componentTemp + "-" + href.replace("#", "")).empty();
                                        $(".architecture-phobius").remove();
                                        var signal = false;
                                        var cleavage = "";
                                        architecture = "";
                                        var TMs = 0;
                                        addPanelResult("#evidence-" + componentTemp + "-" + href.replace("#", ""), "<table class='table table-striped table-hover'><thead><tr><th>Direction</th><th>Start</th><th>End</th></tr></thead><tbody id='tableArchitecturePhobius-"+href.replace("#", "")+"' class='architecture-phobius' class='collapsed'></tbody></table>");
                                        for (var j = 0; j < responseIntervals.properties.length; j++) {
                                            if (responseIntervals.properties[j].classification == 'SIGNAL') {
                                                signal = true;
                                            }
                                            if (responseIntervals.properties[j].hasOwnProperty("cleavage_position1")) {
                                                cleavage += responseIntervals.properties[j].cleavage_position1;
                                            }
                                            if (responseIntervals.properties[j].hasOwnProperty("cleavage_position2")) {
                                                cleavage += " - " + responseIntervals.properties[j].cleavage_position2;
                                            }
                                            if (responseIntervals.properties[j].hasOwnProperty("predicted_TMHs")) {
                                                TMs = responseIntervals.properties[j].predicted_TMHs;
                                            }
                                            if (responseIntervals.properties[j].hasOwnProperty("region")) {
                                                if (responseIntervals.properties[j].region == "NON CYTOPLASMIC") {
                                                    $("#tableArchitecturePhobius-"+href.replace("#", "")).append("<tr><td>Outside the cytoplasm</td><td>"+responseIntervals.properties[j].fstart+"</td><td>"+responseIntervals.properties[j].fend+"</td></tr>");
                                                    architecture += "O";
                                                } else if (responseIntervals.properties[j].region == "TRANSMEM") {
                                                    $("#tableArchitecturePhobius-"+href.replace("#", "")).append("<tr><td>Transmembrane helix</td><td>"+responseIntervals.properties[j].fstart+"</td><td>"+responseIntervals.properties[j].fend+"</td></tr>");
                                                    architecture += "T";
                                                } else if (responseIntervals.properties[j].region == "CYTOPLASMIC") {
                                                    $("#tableArchitecturePhobius-"+href.replace("#", "")).append("<tr><td>Inside the cytoplasm</td><td>"+responseIntervals.properties[j].fstart+"</td><td>"+responseIntervals.properties[j].fend+"</td></tr>");
                                                    architecture += "I";
                                                }
                                                if (!(j == responseIntervals.properties.length - 1)) {
                                                    architecture += "-";
                                                }
                                            }
                                        }
                                        if (signal) {
                                            listHTMLs[counterHTMLs] = "<div class='row architecture-phobius'><div class='col-md-3'><p>Signal peptide:</p></div><div class='col-md-9'><p>Yes</p></div></div>";
                                            counterHTMLs++;
                                        }
                                        if (cleavage != "") {
                                            listHTMLs[counterHTMLs] = "<div class='row architecture-phobius'><div class='col-md-3'><p>Cleavage positions:</p></div><div class='col-md-9'><p>" + cleavage + "</p></div></div>";
                                            counterHTMLs++;
                                        }
                                        if (TMs != 0) {
                                            listHTMLs[counterHTMLs] = "<div class='row architecture-phobius'><div class='col-md-3'><p>Transmembrane domains:</p></div><div class='col-md-9'><p>" + TMs + "</p></div></div>";
                                            counterHTMLs++;
                                        }
                                        //									if (architecture != "") {
                                        //										listHTMLs[counterHTMLs] = "<div class='row architecture-phobius'><div class='col-md-3'><p>Architecture:</p></div><div class='col-md-9'><p>" + architecture + "</p></div></div>";
                                        //										counterHTMLs++;
                                        //										listHTMLs[counterHTMLs] = "<div class='row architecture-phobius'><div class='col-md-12'><div class='alert alert-info'><p>Architecture legend: O, outside the cytoplasm; T, transmembrane domain; I, inside the cytoplasm</p></div></div></div>";
                                        //										counterHTMLs++;
                                        //									}
                                        idTable = "#evidence-" + componentTemp + "-" + href.replace("#", "");
                                    }
                                    // addPanelResult("#subevidence-"+data.id, html);
                                    for (var index in listHTMLs) {
                                        addPanelResult(idTable, listHTMLs[index]);
                                    }
                                    console.log(responseIntervals);
                                }
                            }
                        }
                    });
                }
            }
        }

        if (data.type == "tRNAscan") {
            var data = getIntervalEvidenceProperties(href.replace("#", ""), data.type).responseJSON.response;
            var htmlBasic = getHTMLContent("search-database/tRNABasicResult.tt").responseJSON.response;
            htmlBasic = htmlBasic.replace("[% result.type %]", product);
            htmlBasic = htmlBasic.replace("[% result.aminoacid %]", data.properties[0].aminoacid);
            htmlBasic = htmlBasic.replace("[% result.anticodon %]", data.properties[0].anticodon);
            htmlBasic = htmlBasic.replace("[% result.anticodon_start %]", data.properties[0].anticodon_start);
            htmlBasic = htmlBasic.replace("[% result.anticodon_end %]", data.properties[0].anticodon_end);
            htmlBasic = htmlBasic.replace("[% result.codon %]", data.properties[0].codon);
            htmlBasic = htmlBasic.replace("[% result.score %]", data.properties[0].score);
            htmlBasic = htmlBasic.replace("[% result.pseudogene %]", data.properties[0].pseudogene);
            htmlBasic = htmlBasic.replace("[% result.download %]", "<a href='"+window.location.pathname.replace("/SearchDatabase", "")+"/DownloadFileByContigAndType?contig=" + name + "&type=" + type.replace("_scan", "").toLowerCase() + "' target='_blank'>Link</a>");
            htmlContent += htmlBasic;
            if (data.properties[0].hasOwnProperty("intron")) {
                if (data.properties[0].intron == "yes") {
                    htmlBasic = getHTMLContent("search-database/tRNABasicResultHasIntron.tt").responseJSON.response;
                    htmlBasic = htmlBasic.replace("[% result.intron %]", data.properties[0].intron);
                    htmlBasic = htmlBasic.replace("[% result.coordinatesGene %]", data.properties[0].intron_start);
                    htmlBasic = htmlBasic.replace("[% result.coordinatesGenome %]", data.properties[0].intron_start_seq);
                    htmlContent += htmlBasic;
                }
            }
            htmlContent += htmlSequence;
            addPanelResult(href, htmlContent);


        } else if (data.type == "RNA_scan") {
            var data = getIntervalEvidenceProperties(href.replace("#", ""), data.type).responseJSON.response;
            htmlBasic = getHTMLContent("search-database/rnaScanBasicResult.tt").responseJSON.response;
            htmlBasic = htmlBasic.replace("[% result.target_description %]", data.properties[0].target_description);
            htmlBasic = htmlBasic.replace("[% result.score %]", data.properties[0].score);
            htmlBasic = htmlBasic.replace("[% result.evalue %]", data.properties[0].evalue);
            htmlBasic = htmlBasic.replace("[% result.target_identifier %]", data.properties[0].target_identifier);
            htmlBasic = htmlBasic.replace("[% result.target_name %]", data.properties[0].target_name);
            htmlBasic = htmlBasic.replace("[% result.target_class %]", data.properties[0].target_class);
            htmlBasic = htmlBasic.replace("[% result.bias %]", data.properties[0].bias);
            htmlBasic = htmlBasic.replace("[% result.truncated %]", data.properties[0].truncated);
            htmlBasic = htmlBasic.replace("[% result.download %]", "<a href='"+window.location.pathname.replace("/SearchDatabase", "")+"/DownloadFileByContigAndType?contig=" + name + "&type=" + type.replace("_scan", "").toLowerCase() + "' target='_blank'>Link</a>");
            htmlContent += htmlBasic;
            htmlContent += htmlSequence;
            addPanelResult(href, htmlContent);
        } else if (data.type == "rRNA_prediction") {
            var data = getIntervalEvidenceProperties(href.replace("#", ""), data.type).responseJSON.response;
            var htmlBasic = getHTMLContent("search-database/rRNAPredictionBasicResult.tt").responseJSON.response;
            htmlBasic = htmlBasic.replace("[% result.molecule_type %]", data.properties[0].molecule_type);
            htmlBasic = htmlBasic.replace("[% result.score %]", data.properties[0].score);
            htmlBasic = htmlBasic.replace("[% result.download %]", "<a href='"+window.location.pathname.replace("/SearchDatabase", "")+"/DownloadFileByContigAndType?contig=" + name + "&type=" + type.replace("_scan", "").toLowerCase() + "' target='_blank'>Link</a>");
            htmlContent += htmlBasic;
            htmlContent += htmlSequence;
            addPanelResult(href, htmlContent);
        }
    } else {
        $(href).removeClass("collapsed");
        $(href).addClass("collapse");
        $(href + " .row").remove();
        $(href + " .sequences").remove();
        $(href + " .panel").remove();
        $(href).hide();
    }
}

/**
 * Method used to add a panel of results in default panel
 * 
 * @param href
 *            of the panel
 * @param htmlContent
 *            to be added
 * @returns
 */
function addPanelResult(href, htmlContent) {
    $(href).append(htmlContent);
    $(href).removeClass("collapse");
    $(href).addClass("collapsed");
    $(href).show();
}

/**
 * Method used to change view and show data from the contig search
 */
$(function() {
    $("#formSearchContig").submit(
            function() {
                $(".errors").remove();
                var data = searchContig($(this).serialize()).responseJSON.response;
                var htmlContent = getHTMLContent("search-database/contigs.tt").responseJSON.response;
                htmlContent = htmlContent.replace(/(\[\% sequence.path \%\])+/gim, window.location.pathname.replace("/SearchDatabase", "")); 
                htmlContent = htmlContent.replace(/(\[\% sequence.id \%\])+/gim, data.geneID);
                htmlContent = htmlContent.replace(/(\[\% sequence.name \%\])+/gim, data.gene);
                htmlContent = htmlContent.replace(/(\[\% start \%\])+/gim, $("input[name=contigStart]").val());
                htmlContent = htmlContent.replace(/(\[\% end \%\])/gim, $("input[name=contigEnd]").val());
                htmlContent = htmlContent.replace(/(\[\% hadReverseComplement \%\])/gim, data.reverseComplement);
                htmlContent = htmlContent.replace(/(\[\% sequence.id \%\])+/gim, data.geneID);
                var sequence = ">"+data.gene;
                if($("input[name=contigStart]").val() != "" && $("input[name=contigEnd]").val() != "") {
                    sequence += "_("+$("input[name=contigStart]").val() + "-"+$("input[name=contigEnd]").val()+")";
                }
                if(data.reverseComplement == 1) {
                    sequence += "_reverse_complemented";
                }
                sequence += "<br />"+ data.contig;
                htmlContent = htmlContent.replace(/(\[\% contig \%\])+/gim, sequence);
                $("#searchPanel").hide();
                $("#back").show();
                $("#searchPanel").parent().append(htmlContent);
                //			var titlePanel = "Contig search results";
                //			if ($("input[name=contigStart]").val() != "" &&
                //				$("input[name=contigEnd]").val() != "") {
                //				titlePanel += "from "
                //					+ $("input[name=contigStart]").val()
                //					+ " to "
                //					+ $("input[name=contigEnd]").val() + " of ";
                //			}
                //			titlePanel += data.gene;
                //			if ($("input[name=revCompContig]").is(":checked")) {
                //				titlePanel += ", reverse complemented";
                //			}
                //			titlePanel += ")";
                //			$("#title-panel").text(titlePanel);
                return false;
            }
    );
});

$("input[name=tmhmmQuant]").change(function() {
    if($("input[name=tmhmmQuant]:checked").val() == "none")
        $("input[name=TMHMMdom]").prop("disabled", true);
    else
        $("input[name=TMHMMdom]").prop("disabled", false);
});
$("input[name=tmQuant]").change(function() {
    if($("input[name=tmQuant]:checked").val() == "none")
        $("input[name=TMdom]").prop("disabled", true);
    else
        $("input[name=TMdom]").prop("disabled", false);
});
$("input[name=cleavageQuant]").change(function() {
    if($("input[name=cleavageQuant]:checked").val() == "none")
        $("input[name=cleavageSiteDGPI]").prop("disabled", true);
    else
        $("input[name=cleavageSiteDGPI]").prop("disabled", false);
});
$("input[name=scoreQuant]").change(function() {
    if($("input[name=scoreQuant]:checked").val() == "none")
        $("input[name=scoreDGPI]").prop("disabled", true);
    else
        $("input[name=scoreDGPI]").prop("disabled", false);
});
$("input[name=positionQuantPreDGPI]").change(function() {
    if($("input[name=positionQuantPreDGPI]:checked").val() == "none")
        $("input[name=positionPreDGPI]").prop("disabled", true);
    else
        $("input[name=positionPreDGPI]").prop("disabled", false);
});
$("input[name=specificityQuantPreDGPI]").change(function() {
    if($("input[name=specificityQuantPreDGPI]:checked").val() == "none")
        $("input[name=specificityPreDGPI]").prop("disabled", true);
    else
        $("input[name=specificityPreDGPI]").prop("disabled", false);
});
$("input[name=pvalueQuantBigpi]").change(function() {
    if($("input[name=pvalueQuantBigpi]:checked").val() == "none")
        $("input[name=pvalueBigpi]").prop("disabled", true);
    else
        $("input[name=pvalueBigpi]").prop("disabled", false);
});
$("input[name=positionQuantBigpi]").change(function() {
    if($("input[name=positionQuantBigpi]:checked").val() == "none")
        $("input[name=positionBigpi]").prop("disabled", true);
    else
        $("input[name=positionBigpi]").prop("disabled", false);
});
$("input[name=ncRNAevM]").change(function() {
    if($("input[name=ncRNAevM]:checked").val() == "none")
        $("input[name=ncRNAevalue]").prop("disabled", true);
    else
        $("input[name=ncRNAevalue]").prop("disabled", false);
});
$("input[name=TRFsize]").change(function() {
    if($("input[name=TRFsize]:checked").val() == "none")
        $("input[name=TRFrepSize]").prop("disabled", true);
    else
        $("input[name=TRFrepSize]").prop("disabled", false);
});
$("input[name=TTconfM]").change(function() {
    if($("input[name=TTconfM]:checked").val() == "none")
        $("input[name=TTconf]").prop("disabled", true);
    else
        $("input[name=TTconf]").prop("disabled", false);
});
$("input[name=TThpM]").change(function() {
    if($("input[name=TThpM]:checked").val() == "none")
        $("input[name=TThp]").prop("disabled", true);
    else
        $("input[name=TThp]").prop("disabled", false);
});
$("input[name=TTtailM]").change(function() {
    if($("input[name=TTtailM]:checked").val() == "none")
        $("input[name=TTtail]").prop("disabled", true);
    else
        $("input[name=TTtail]").prop("disabled", false);
});
$("input[name=AHlenM]").change(function() {
    if($("input[name=AHlenM]:checked").val() == "none")
        $("input[name=AHlen]").prop("disabled", true);
    else
        $("input[name=AHlen]").prop("disabled", false);
});
$("input[name=AHscM]").change(function() {
    if($("input[name=AHscM]:checked").val() == "none")
        $("input[name=AHscore]").prop("disabled", true);
    else
        $("input[name=AHscore]").prop("disabled", false);
});
$("input[name=AHthrM]").change(function() {
    if($("input[name=AHthrM]:checked").val() == "none")
        $("input[name=AHthr]").prop("disabled", true);
    else
        $("input[name=AHthr]").prop("disabled", false);
});

$("input[name=scoreQuantBigpi]").change(function() {
    if($("input[name=scoreQuantBigpi]:checked").val() == "none")
        $("input[name=scoreBigpi]").prop("disabled", true);
    else
        $("input[name=scoreBigpi]").prop("disabled", false);
});
