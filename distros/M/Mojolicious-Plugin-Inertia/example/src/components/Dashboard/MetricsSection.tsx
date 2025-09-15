import { router } from '@inertiajs/react'

type Props = {
  metrics?: {
    last_updated: string
    random_metric: number
    server_load: string
  }
  loadingSection: string | null
  setLoadingSection: (section: string | null) => void
  autoRefreshMetrics: boolean
  setAutoRefreshMetrics: (auto: boolean) => void
}

export default function MetricsSection({
  metrics,
  loadingSection,
  setLoadingSection,
  autoRefreshMetrics,
  setAutoRefreshMetrics
}: Props) {
  const refreshMetrics = () => {
    setLoadingSection('metrics')
    router.reload({
      only: ['metrics'],
      onFinish: () => setLoadingSection(null),
    })
  }

  return (
    <div className="mb-8">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold text-gray-800">
          Live Metrics
          {loadingSection === 'metrics' && <span className="text-sm text-gray-500 ml-2">(Updating...)</span>}
          {autoRefreshMetrics && <span className="text-sm text-green-600 ml-2">(Auto-refresh ON)</span>}
        </h2>
        <div className="flex gap-2">
          <button
            onClick={refreshMetrics}
            disabled={loadingSection !== null}
            className="px-3 py-1 bg-gray-500 text-white rounded hover:bg-gray-600 disabled:opacity-50 transition-colors"
          >
            Refresh Metrics Only
          </button>
          <button
            onClick={() => setAutoRefreshMetrics(!autoRefreshMetrics)}
            className={`px-3 py-1 rounded transition-colors ${
              autoRefreshMetrics
                ? 'bg-red-600 text-white hover:bg-red-700'
                : 'bg-gray-600 text-white hover:bg-gray-700'
            }`}
          >
            {autoRefreshMetrics ? 'Stop' : 'Start'} Auto
          </button>
        </div>
      </div>
      {metrics ? (
        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Last Updated:</span>
              <span className="font-mono text-sm">{metrics.last_updated}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Random Metric:</span>
              <span className="font-bold text-lg">{metrics.random_metric}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Server Load:</span>
              <span className="font-bold text-lg">{metrics.server_load}</span>
            </div>
          </div>
        </div>
      ) : (
        <div className="bg-gray-100 p-8 rounded-lg text-center text-gray-500">
          Metrics data not loaded
        </div>
      )}
    </div>
  )
}
