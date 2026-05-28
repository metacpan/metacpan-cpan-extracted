/**
 * Natural Language Search for TicketSQL and Format
 * Uses htmx for form submission and event handling
 * Returns JSON with both query and format strings
 */
export function initNaturalLanguageSearch() {
  // Wait for htmx to be available
  if (typeof htmx === 'undefined') {
    return;
  }

  // Wait for jQuery to be available (for DOM manipulation)
  if (typeof jQuery === 'undefined') {
    return;
  }

  jQuery(function($) {
    const form = document.getElementById('natural-language-search-form');
    if (!form) {
      return;
    }

    const $generateBtn = $('#generate-ticketsql-btn');
    const $errorDiv = $('#nl-search-error');
    const $messageDiv = $('#nl-search-message');
    const $queryTextarea = $('textarea[name="Query"]');
    const $formatTextarea = $('textarea[name="Format"]');

    // Handle before request - show loading state
    form.addEventListener('htmx:beforeRequest', function(event) {
      $generateBtn.prop('disabled', true);
      $errorDiv.addClass('d-none');
      $messageDiv.addClass('d-none');
    });

    // Handle after successful request
    form.addEventListener('htmx:afterRequest', function(event) {
      $generateBtn.prop('disabled', false);

      if (event.detail.successful) {
        const responseText = event.detail.xhr.responseText;

        if (responseText && responseText.trim()) {
          try {
            // Parse JSON response
            const response = JSON.parse(responseText);

            if (response.success) {
              // Write the generated TicketSQL to the Query textarea
              if (response.query) {
                $queryTextarea.val(response.query);
                $queryTextarea.trigger('change');
              }

              // Write the generated Format to the Format textarea
              if (response.format && $formatTextarea.length) {
                $formatTextarea.val(response.format);
                $formatTextarea.trigger('change');
              }

              // Show success message
              if (response.message) {
                $messageDiv.text(response.message).removeClass('d-none');
              }

              if (typeof $.jGrowl === 'function') {
                $.jGrowl('Search and format generated', { sticky: false });
              }
            } else {
              // API returned success: false
              const errorMsg = response.message || 'Failed to generate search. Please try again.';
              $errorDiv.text(errorMsg).removeClass('d-none');
            }
          } catch (e) {
            // Fallback: treat as plain text TicketSQL (backwards compatibility)
            console.warn('Response was not JSON, treating as plain TicketSQL:', e);
            $queryTextarea.val(responseText.trim());
            $queryTextarea.trigger('change');

            if (typeof $.jGrowl === 'function') {
              $.jGrowl('Search generated', { sticky: false });
            }
          }
        } else {
          $errorDiv.text('No search query was generated. Please try rephrasing your request.')
                   .removeClass('d-none');
        }
      }
    });

    // Handle request errors
    form.addEventListener('htmx:responseError', function(event) {
      $generateBtn.prop('disabled', false);

      let errorMessage = 'Failed to generate search. Please try again.';
      if (event.detail.xhr && event.detail.xhr.responseText) {
        try {
          const response = JSON.parse(event.detail.xhr.responseText);
          if (response.message) {
            errorMessage = response.message;
          }
        } catch (e) {
          errorMessage += ' ' + event.detail.xhr.responseText;
        }
      }

      $errorDiv.text(errorMessage).removeClass('d-none');
    });
  });
}
